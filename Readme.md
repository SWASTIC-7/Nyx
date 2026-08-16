# Nyx

A two-stage x86 BIOS bootloader, built from scratch as a systems-programming
learning project. It starts life as a single 512-byte boot sector and grows
into a real loader: it reads a FAT filesystem, shows a GRUB-like boot menu,
paints a graphical splash, switches the CPU into 32-bit protected mode, and
hands off to a kernel using the Multiboot protocol.

## About

Nyx boots a disk image entirely in real mode, then transitions to protected
mode and launches the kernel you pick from the menu. The whole pipeline:

```
BIOS ─▶ MBR (stage 1, LBA) ─▶ Stage 2
          ├─ detect FAT12 / FAT32 (auto)
          ├─ read NYX.CFG ─▶ boot MENU ─▶ you pick NyxOS / NyxOS2
          ├─ VGA splash (mode 12h, 640×480)
          ├─ enable A20 · grab E820 memory map · load GDT
          ├─ switch to 32-bit protected mode (far jump)
          └─ Multiboot handoff ─▶ kernel
```

Read the complete blog on writing bootloader from scratch [here](https://swastic-7.github.io/sw4sy-Bl0gs/before-the-operating-system-booting-nyx)

**Features**
- Two-stage boot: a 512-byte MBR that loads a larger Stage 2 via LBA (`int 13h/AH=42h`)
- FAT12 **and** FAT32 drivers with build-time auto-detection
- GRUB-like boot menu driven by a `NYX.CFG` file (arrow keys + timeout)
- A20 gate, E820 memory map, flat GDT, and the real → protected mode switch
- Multiboot-compliant handoff (magic `0x2BADB002` + memory map)
- Graphical VGA splash (mode 12h) rendering the selected kernel's name
- A headless test harness: static FAT-layout checks + runtime QEMU/GDB checkpoints

## File structure

```
Nyx/
├── Makefile                  # build · run · test · clean
├── nyx_boot.mp4              # demo recording
├── src/
│   ├── nyx.cfg               # boot-menu config: timeout, default, kernel entries
│   ├── bootloader/
│   │   ├── mbr.asm           # stage 1 — 512-byte boot sector, loads stage 2 (LBA)
│   │   ├── stage2.asm        # stage 2 — orchestrates the entire boot
│   │   ├── fat12.asm         # FAT12 driver
│   │   ├── fat32.asm         # FAT32 driver
│   │   ├── menu.asm          # boot menu — parses NYX.CFG, keyboard + timeout
│   │   ├── a20.asm           # A20 gate: enable + verify
│   │   ├── e820.asm          # BIOS E820 memory-map collection
│   │   ├── gdt.asm           # flat 32-bit Global Descriptor Table
│   │   ├── splash.asm        # VGA mode-12h graphical splash
│   │   └── glyphs.inc        # generated bitmap letterforms for the splash
│   ├── kernel_asm/
│   │   └── mb_kernel.asm     # the two demo Multiboot kernels (NyxOS / NyxOS2)
│   └── kernel_c/             # earlier-stage 32-bit C kernel (not in the main build)
│       ├── kernel.c
│       ├── kernel_entry.asm
│       └── linker.ld
├── tests/
│   ├── check_image.py        # static: verify on-disk FAT layout
│   ├── run_checkpoints.py    # runtime: register/memory checkpoints via QEMU + GDB
│   ├── gdb_driver.py
│   └── checkpoints*.json      # expected values for the checkpoints
└── build/                    # generated: disk.img, *.bin, listings
```

## Build & run

Nyx builds and runs on Linux (or WSL on Windows).

```bash
make          # build build/disk.img (the bootable menu disk)
make run      # boot it in QEMU: menu → pick a kernel → splash → kernel
make test     # static FAT-layout checks + runtime QEMU/GDB checkpoints
make clean    # remove build/
```

At the menu, use the **↑/↓** arrow keys to choose **NyxOS** or **NyxOS2** and
press **Enter** (or wait for the timeout to boot the default).

## Dependencies

| Tool | Used for |
|------|----------|
| `nasm` | assembling the bootloader and kernels |
| `qemu-system-i386` | running the disk image |
| `mtools` (`mcopy`) | copying files into the FAT image |
| `dosfstools` (`mkfs.fat`) | formatting the FAT image |
| `make`, `dd` | build orchestration and image stitching |
| `python3`, `gdb` | the test harness only (`make test`) |

Install everything on Debian/Ubuntu/WSL:

```bash
sudo apt install nasm qemu-system-x86 mtools dosfstools make python3 gdb
```

## Resources

Things that helped while building Nyx:

- [Blog — _Before the Operating System: Booting Nyx](https://swastic-7.github.io/sw4sy-Bl0gs/before-the-operating-system-booting-nyx) — the full write-up of how this was built, step by step. <!-- add link -->
- [OSDev Wiki](https://wiki.osdev.org/) — bootloaders, GDT, A20, protected mode, VGA
- [Multiboot Specification](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html)
- [Microsoft FAT specification](https://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/fatgen103.doc)
- [Ralf Brown's Interrupt List](https://www.cs.cmu.edu/~ralf/files.html) — the reference for BIOS `int 10h/13h/15h/16h`
- [FAT12 next-cluster arithmetic (MS KB Q65541)](https://jeffpar.github.io/kbarchive/kb/065/Q65541/)