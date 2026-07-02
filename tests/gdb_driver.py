# Runs INSIDE gdb:  gdb -q -batch -nx -x tests/gdb_driver.py
# Connects to QEMU's gdb stub and asserts register/memory at each checkpoint.
import gdb, json, time

cps = json.load(open("build/checkpoints_resolved.json"))

def x(cmd): return gdb.execute(cmd, to_string=True)

# read a 32-bit base register and slice out 8/16-bit sub-registers by name
REG = {
    'al':('eax',0xFF,0), 'ah':('eax',0xFF,8), 'ax':('eax',0xFFFF,0),
    'bl':('ebx',0xFF,0), 'bh':('ebx',0xFF,8), 'bx':('ebx',0xFFFF,0),
    'cl':('ecx',0xFF,0), 'ch':('ecx',0xFF,8), 'cx':('ecx',0xFFFF,0),
    'dl':('edx',0xFF,0), 'dh':('edx',0xFF,8), 'dx':('edx',0xFFFF,0),
    'si':('esi',0xFFFF,0), 'di':('edi',0xFFFF,0),
}
def rv(name):
    base, mask, sh = REG.get(name, (name, 0xFFFFFFFF, 0))
    v = int(gdb.parse_and_eval('$' + base)) & 0xFFFFFFFF
    return (v >> sh) & mask
def pc_lin():
    cs  = int(gdb.parse_and_eval('$cs'))  & 0xFFFF
    eip = int(gdb.parse_and_eval('$eip')) & 0xFFFF
    return (cs * 16 + eip) & 0xFFFFF
def rd(addr, n): return bytes(gdb.selected_inferior().read_memory(addr, n))
def as_int(v):
    return int(v, 16) if isinstance(v, str) and v.lower().startswith('0x') else int(v)

def run_asserts(cp):
    fails = 0
    for a in cp['asserts']:
        if 'reg' in a:
            got, want = rv(a['reg']), as_int(a['eq'])
            ok, detail = got == want, f"{a['reg']}={got}(0x{got:x}) want {want}"
        elif 'mem8' in a:
            got = rd(a['_addr'], 1)[0]; want = as_int(a['eq'])
            ok, detail = got == want, f"[{a['mem8']}]={got} want {want}"
        elif 'mem16' in a:
            got = int.from_bytes(rd(a['_addr'], 2), 'little'); want = as_int(a['eq'])
            ok, detail = got == want, f"[{a['mem16']}]={got} want {want}"
        elif 'memstr' in a:
            got = rd(a['_addr'], len(a['eq'])).decode('latin1')
            ok, detail = got == a['eq'], f"'{got}' want '{a['eq']}'"
        elif 'memcmp' in a:
            m = a['memcmp']; want = open(m['file'], 'rb').read()[:m['len']]
            got = rd(as_int(m['addr']), m['len'])
            ok, detail = got == want, f"{m['len']} bytes @ {m['addr']} vs {m['file']}"
        else:
            ok, detail = False, "unknown assert"
        print(f"[{'PASS' if ok else 'FAIL'}] {cp['name']}: {detail}")
        if not ok: fails += 1
    return fails

x("set pagination off")
x("set confirm off")
for _ in range(50):
    try: x("target remote :1234"); break
    except gdb.error: time.sleep(0.1)

for addr in sorted({cp['pc'] for cp in cps}):
    x(f"hbreak *{addr:#x}")

fails, remaining, hits = 0, list(range(len(cps))), {}
x("continue")
for _ in range(300):
    pc = pc_lin(); hits[pc] = hits.get(pc, 0) + 1
    done = []
    for idx in remaining:
        cp = cps[idx]
        if cp['pc'] == pc and cp.get('hit', 1) == hits[pc]:
            fails += run_asserts(cp); done.append(idx)
    for idx in done: remaining.remove(idx)
    if not remaining: break
    x("continue")
for idx in remaining:
    print(f"[FAIL] {cps[idx]['name']}: never reached"); fails += 1
print(f"RESULT {fails}")
