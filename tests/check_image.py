#!/usr/bin/env python3
# Layer 1 - static checks on the built disk image (no emulator needed).
# Verifies the FAT12 on-disk layout matches our design and that KERNEL.BIN
# is placed exactly where the bootloader will look for it.
import struct, sys, math

FAILS = 0
def check(name, cond, detail=""):
    global FAILS
    if not cond: FAILS += 1
    print(f"[{'PASS' if cond else 'FAIL'}] {name}" + (f"   {detail}" if detail else ""))

def u16(b, o): return struct.unpack_from("<H", b, o)[0]
def u32(b, o): return struct.unpack_from("<I", b, o)[0]

img  = open("build/disk.img", "rb").read()
kern = open("build/kernel.bin", "rb").read()

# ---- boot signature ----
check("boot signature 0x55AA @510", img[510:512] == b"\x55\xAA", img[510:512].hex())

# ---- BPB fields ----
bps      = u16(img, 0x0B)
spc      = img[0x0D]
reserved = u16(img, 0x0E)
nfats    = img[0x10]
rootent  = u16(img, 0x11)
spf      = u16(img, 0x16)
check("bytes/sector == 512",   bps == 512,      f"={bps}")
check("sectors/cluster == 1",  spc == 1,        f"={spc}")
check("reserved == 17",        reserved == 17,  f"={reserved}")
check("num FATs == 2",         nfats == 2,      f"={nfats}")
check("root entries == 224",   rootent == 224,  f"={rootent}")
check("sectors/FAT == 9",      spf == 9,        f"={spf}")

# ---- region math ----
fat_start    = reserved
root_start   = reserved + nfats * spf
root_sectors = math.ceil(rootent * 32 / bps)
data_start   = root_start + root_sectors
check("fat_start == 17",  fat_start == 17,   f"={fat_start}")
check("root_start == 35", root_start == 35,  f"={root_start}")
check("data_start == 49", data_start == 49,  f"={data_start}")

# ---- FAT #1, decode 12-bit entries ----
fat = img[fat_start * bps : (fat_start + spf) * bps]
def fat12(n):
    o = n + (n >> 1)
    w = fat[o] | (fat[o + 1] << 8)
    return (w & 0x0FFF) if n % 2 == 0 else (w >> 4)

# ---- scan root directory for KERNEL.BIN ----
root = img[root_start * bps : (root_start + root_sectors) * bps]
first = size = None
for i in range(0, len(root), 32):
    e = root[i:i+32]
    if e[0] == 0x00: break
    if e[0] == 0xE5: continue
    if e[0:11] == b"KERNEL  BIN":
        first, size = u16(e, 26), u32(e, 28)
        break

check("KERNEL.BIN found in root dir", first is not None)
if first is not None:
    check("first cluster == 2", first == 2, f"={first}")
    check("size == 1536",       size == 1536, f"={size}")

    chain, c, guard = [], first, 0
    while c < 0xFF8 and guard < 1000:
        chain.append(c); c = fat12(c); guard += 1
    check("cluster chain == [2, 3, 4]", chain == [2, 3, 4], f"chain={chain}")
    check("chain ends at EOC (>=0xFF8)", c >= 0xFF8, f"0x{c:03X}")

    data = b""
    for cl in chain:
        lba = data_start + (cl - 2) * spc
        data += img[lba * bps : (lba + spc) * bps]
    check("kernel bytes on disk == kernel.bin", data[:len(kern)] == kern,
          f"{len(data)} bytes vs {len(kern)}")

print()
if FAILS:
    print(f"IMAGE CHECKS: {FAILS} FAILED"); sys.exit(1)
print("IMAGE CHECKS: ALL PASSED")
