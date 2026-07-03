#!/usr/bin/env python3
# Layer 1 - static checks on a built disk image (no emulator needed).
# Auto-detects FAT12 (VBR in sector 0) vs FAT32 (MBR + partition) and verifies
# the on-disk layout matches our design, and that KERNEL.BIN is placed where the
# bootloader will look for it.
import struct, sys, math

FAILS = 0
def check(name, cond, detail=""):
    global FAILS
    if not cond: FAILS += 1
    print(f"[{'PASS' if cond else 'FAIL'}] {name}" + (f"   {detail}" if detail else ""))

def u16(b, o): return struct.unpack_from("<H", b, o)[0]
def u32(b, o): return struct.unpack_from("<I", b, o)[0]

img_path  = sys.argv[1] if len(sys.argv) > 1 else "build/disk.img"
kern_path = sys.argv[2] if len(sys.argv) > 2 else "build/kernel.bin"
part_idx  = int(sys.argv[3]) if len(sys.argv) > 3 else 0
target    = (sys.argv[4].encode() if len(sys.argv) > 4 else b"KERNEL  BIN")
img  = open(img_path, "rb").read()
kern = open(kern_path, "rb").read()
print(f"# checking {img_path} (partition {part_idx}, kernel {kern_path})")

check("boot signature 0x55AA @510", img[510:512] == b"\x55\xAA", img[510:512].hex())

pe = 0x1BE + part_idx * 16
part_type = img[pe + 4]
is_fat32  = part_type != 0

def sec(lba, n=1): return img[lba*512:(lba+n)*512]

def scan_dir(entries):
    for i in range(0, len(entries), 32):
        e = entries[i:i+32]
        if e[0] == 0x00: return None
        if e[0] == 0xE5: continue
        if e[0:11] == target:
            first = (u16(e, 0x14) << 16) | u16(e, 0x1A)
            return first, u32(e, 28)
    return None

if not is_fat32:
    # ---------- FAT12 ----------
    bps, spc = u16(img, 0x0B), img[0x0D]
    reserved, nfats = u16(img, 0x0E), img[0x10]
    rootent, spf = u16(img, 0x11), u16(img, 0x16)
    check("FAT12: reserved == 17", reserved == 17, f"={reserved}")
    check("FAT12: sectors/FAT == 9", spf == 9, f"={spf}")

    fat_start = reserved
    root_start = reserved + nfats * spf
    root_sectors = math.ceil(rootent * 32 / bps)
    data_start = root_start + root_sectors
    check("fat_start == 17", fat_start == 17, f"={fat_start}")
    check("data_start == 49", data_start == 49, f"={data_start}")

    fat = sec(fat_start, spf)
    def nxt(n):
        o = n + (n >> 1); w = fat[o] | (fat[o+1] << 8)
        return (w & 0x0FFF) if n % 2 == 0 else (w >> 4)
    eoc = 0xFF8
    found = scan_dir(sec(root_start, root_sectors))
    expect_first = 2
else:
    # ---------- FAT32 ----------
    pstart = u32(img, pe + 8)
    check("MBR partition type == 0x0C", part_type == 0x0C, hex(part_type))
    check("partition start LBA is set", pstart >= 2048, f"={pstart}")

    b = pstart * 512           # byte offset of the partition VBR
    bps, spc = u16(img, b+0x0B), img[b+0x0D]
    reserved, nfats = u16(img, b+0x0E), img[b+0x10]
    spf16, spf = u16(img, b+0x16), u32(img, b+0x24)
    rootclus = u32(img, b+0x2C)
    check("FAT32: spf16 == 0 (is FAT32)", spf16 == 0, f"={spf16}")
    check("FAT32: reserved == 32", reserved == 32, f"={reserved}")

    fat_start = pstart + reserved
    data_start = pstart + reserved + nfats * spf
    check("fat_start == pstart + reserved", fat_start == pstart + reserved, f"={fat_start}")
    check("data_start > fat_start", data_start > fat_start, f"={data_start}")

    def nxt(n):
        o = n*4; s = fat_start + o//512
        return u32(sec(s), o % 512) & 0x0FFFFFFF
    eoc = 0x0FFFFFF8
    def clus_lba(c): return data_start + (c-2)*spc
    # root dir is a cluster chain
    found, c = None, rootclus
    for _ in range(64):
        found = scan_dir(sec(clus_lba(c), spc))
        if found is not None: break
        c = nxt(c)
        if c >= eoc: break
    expect_first = 3

check(f"{target.decode().strip()} found", found is not None)
if found is not None:
    first, size = found
    check(f"first cluster == {expect_first}", first == expect_first, f"={first}")
    expect_size = len(kern)
    expect_clusters = math.ceil(expect_size / (spc * 512))
    check(f"size == {expect_size}", size == expect_size, f"={size}")

    chain, c = [], first
    while c < eoc and len(chain) < 1000:
        chain.append(c); c = nxt(c)
    check(f"chain length == {expect_clusters}", len(chain) == expect_clusters, f"chain={chain}")
    check("chain ends at EOC", c >= eoc, f"0x{c:X}")

    if not is_fat32:
        data = b"".join(sec(data_start + (cl-2)*spc, spc) for cl in chain)
    else:
        data = b"".join(sec(data_start + (cl-2)*spc, spc) for cl in chain)
    check("kernel bytes on disk == kernel.bin", data[:len(kern)] == kern,
          f"{len(data)} vs {len(kern)}")

print()
if FAILS:
    print(f"IMAGE CHECKS: {FAILS} FAILED"); sys.exit(1)
print("IMAGE CHECKS: ALL PASSED")
