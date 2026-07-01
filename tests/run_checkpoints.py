#!/usr/bin/env python3
# Layer 2 orchestrator - resolves checkpoint addresses from the NASM listings,
# boots the image under QEMU's gdb stub, and runs the assertions via gdb.
import json, os, re, subprocess, sys, time

def resolve_label(listings, label):
    for org, path in listings:
        lines = open(path).read().splitlines()
        for i, ln in enumerate(lines):
            if re.search(r'(?<![\w.])' + re.escape(label) + r':', ln):
                for j in range(i, min(i + 6, len(lines))):
                    m = re.search(r'\b([0-9A-Fa-f]{8})\b', lines[j])
                    if m:
                        return org + int(m.group(1), 16)
    return None

def as_int(v):
    return int(v, 16) if isinstance(v, str) and v.lower().startswith('0x') else int(v)

def main():
    listings = [(0x7C00, 'build/mbr.lst'), (0x7E00, 'build/stage2.lst')]
    cps = json.load(open('tests/checkpoints.json'))

    for cp in cps:
        cp['pc'] = as_int(cp['addr']) if 'addr' in cp else resolve_label(listings, cp['label'])
        if cp['pc'] is None:
            print(f"[FAIL] {cp['name']}: could not resolve address"); sys.exit(1)
        for a in cp['asserts']:
            if 'mem16' in a:
                a['mem16_addr'] = resolve_label(listings, a['mem16'])
    os.makedirs('build', exist_ok=True)
    json.dump(cps, open('build/checkpoints_resolved.json', 'w'))

    qemu = subprocess.Popen(
        ['qemu-system-i386', '-drive', 'format=raw,file=build/disk.img',
         '-S', '-gdb', 'tcp::1234', '-display', 'none'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    fails = 1
    try:
        time.sleep(0.4)
        out = subprocess.run(['gdb', '-q', '-batch', '-nx', '-x', 'tests/gdb_driver.py'],
                             capture_output=True, text=True, timeout=90)
        for line in out.stdout.splitlines():
            if line.startswith('[PASS]') or line.startswith('[FAIL]'):
                print(line)
        m = re.search(r'RESULT (\d+)', out.stdout)
        if m:
            fails = int(m.group(1))
        else:
            sys.stderr.write(out.stdout + out.stderr)
    finally:
        qemu.kill()

    print()
    if fails:
        print(f"CHECKPOINTS: {fails} FAILED"); sys.exit(1)
    print("CHECKPOINTS: ALL PASSED")

if __name__ == '__main__':
    main()
