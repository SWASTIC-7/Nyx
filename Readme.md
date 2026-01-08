# Nyx — Writing a Bootloader From Scratch

Do you know how an OS gets loaded onto bare metal? Let me explain to you how a bootloader is written from scratch. I will be writing an x86 bootloader, and my effort has been to explain this to a newbie — as I faced a lot of difficulty collecting resources and doing this project myself.



**Repository layout (where to look)**
- Bootloader sources: [src/bootloader/bootloader.asm](src/bootloader/bootloader.asm)
- Disk & FAT helpers: [src/bootloader/disk.asm](src/bootloader/disk.asm), [src/bootloader/fat12.asm](src/bootloader/fat12.asm), [src/bootloader/fat32.asm](src/bootloader/fat32.asm)
- Basic printing: [src/bootloader/print.asm](src/bootloader/print.asm)
- Kernel assembly entry: [src/kernel_asm/main.asm](src/kernel_asm/main.asm)
- Kernel C + entry glue: [src/kernel_c/kernel_entry.asm](src/kernel_c/kernel_entry.asm), [src/kernel_c/kernel.c](src/kernel_c/kernel.c)
- Linker script: [src/kernel_c/linker.ld](src/kernel_c/linker.ld)

Introduction
------------

Bootloaders are small programs that run immediately after firmware (BIOS or UEFI) hands off control. For BIOS-based PCs, the firmware reads 512 bytes from a boot device into memory at 0x7C00 and jumps to it. That 512-byte chunk must include a valid boot signature (0x55AA) and often contains just enough code to load a larger second-stage loader that implements more advanced features.

```bash
0x00000 ┌─────────────────────────┐
        │ Interrupt Vector Table  │  1 KB
0x00400 ├─────────────────────────┤
        │ BIOS Data Area          │  256 B
0x00500 ├─────────────────────────┤
        │ Free (usable)           │  ~30 KB
0x07C00 ├─────────────────────────┤
        │ ★ YOUR BOOT SECTOR ★    │  512 B
0x07E00 ├─────────────────────────┤
        │ Free (stage2, kernel)   │  ~480 KB
0x80000 ├─────────────────────────┤
        │ EBDA (varies)           │
0xA0000 ├─────────────────────────┤
        │ Video RAM               │  128 KB
0xC0000 ├─────────────────────────┤
        │ Video BIOS / ROMs       │
0xF0000 ├─────────────────────────┤
        │ System BIOS ROM         │  64 KB
0xFFFFF └─────────────────────────┘
Designing a 2-stage BIOS bootloader
```
-----------------------------------

Why two stages?
- Stage 1 (512 bytes): fits in the boot sector; performs minimal setup and loads stage 2 from disk
- Stage 2 (bigger, located in filesystem): implements UI, disk/FAT parsing, kernel selection, A20 handling, mode switching

Stage 1 responsibilities (what `bootloader.asm` does)
- Validate boot signature
- Set up a minimal environment (stack, segments)
- Use BIOS `int 0x13` to read sectors from disk into memory (commonly 0x0000:0x7E00 or 0x0000:0x0500 / 0x0000:0x8000)
- Jump to stage 2's load address

Useful boot sector constraints
- 512 bytes total; last two bytes 0x55 0xAA
- Keep ISRs, heavy logic, and big tables out of stage 1

BIOS disk I/O (int 0x13) primer
- Function 0x02: read sectors by CHS (old) or use Extended Disk Access (0x42) for LBA with BIOS extensions
- If using floppy / simple test images, CHS reads are sufficient
- For hard disks and modern systems, consider LBA or use the BIOS extensions (EDD)

Example: simple int 0x13 read (concept)
```
mov ah, 0x02 ; read sectors
mov al, count ; number of sectors
mov ch, cylinder
mov cl, sector
mov dh, head
mov dl, drive ; 0x00 floppy A:, 0x80 first HD
mov bx, buffer ; ES:BX points to buffer (set ES correctly)
int 0x13
jc disk_error
```

Filesystem basics — FAT12 and FAT32 (why it's chosen)
- FAT12/FAT32 are simple and ubiquitous on removable images
- Implementation needs: find root dir, parse directory entries, follow FAT chains, and read file clusters
- In this repo `fat12.asm`/`fat32.asm` provide those helpers

A20 line and why it matters
- Real-mode addresses wrap at 1MB (20-bit addresses). Some kernels expect to be loaded above 1MB, so the A20 address line must be enabled to access memory above 1MB without wrap.
- Typical enabling methods: keyboard controller (legacy), BIOS services, or trying both and detecting success.

Protected mode transition (high-level)
- Build a small GDT in memory with at least code/data descriptors
- Load GDT via `lgdt` and set CR0.PE = 1 to enable protected mode
- Perform a far jump to flush prefetch and land in protected-mode code segment
- Set data segment registers and optionally set up paging

Minimal GDT layout (concept)
```
null descriptor
kernel code descriptor (base=0, limit=4GB, type=code/read)
kernel data descriptor (base=0, limit=4GB, type=data/readwrite)
```

Kernel format & boot protocol
- For simple custom kernels: define a small entry stub in assembly (`kernel_entry.asm`) that sets up C calling conventions and then calls `main()` in C (`kernel.c`).
- For broader compatibility, implement multiboot / bzImage loading later. This repo focuses first on a small, test kernel so iteration is faster.

### Some tools You should know
- Nasm
- gdb
- Makefile
- Qemu

Assembly + C integration
------------------------

Typical flow to integrate kernel C code:
1. Provide an assembly entry that does low-level setup (stack, segments, CPU state)
2. Call a C function `kmain()` or `main()` that is compiled with `gcc` (or `clang`) targeting 32-bit (`-m32`) and linked with a suitable `ld` script
3. Ensure calling conventions (cdecl) and symbol names (no mangling) match; use `global`/`extern` in NASM and `extern "C"` if using C++ (not used here)

Example build commands (concept)
```
nasm -f bin src/bootloader/bootloader.asm -o build/boot.bin    # stage1 raw 512-byte sector
nasm -f bin src/bootloader/stage2.asm -o build/stage2.bin     # stage2 raw binary
gcc -m32 -ffreestanding -c src/kernel_c/kernel.c -o build/kernel.o
nasm -f elf32 src/kernel_c/kernel_entry.asm -o build/kernel_entry.o
ld -m elf_i386 -T src/kernel_c/linker.ld build/kernel_entry.o build/kernel.o -o build/kernel.bin
```

Note: Use `-m32` and a multilib toolchain where necessary; on some distributions you may need `gcc-multilib` or equivalent.

Creating a disk image and installing the bootloader
-------------------------------------------------

Common steps:
1. Create an empty image file (e.g., 1.44MB floppy or small HD image)
2. Format it as FAT12/FAT32 (tools: `mformat`, `mkfs.vfat`) or set up partitions
3. Copy stage2, kernel, and other files to the filesystem
4. Write `build/boot.bin` to the first sector of the image using `dd` or `mtools` tools

Example (floppy image)
```
dd if=/dev/zero of=floppy.img bs=512 count=2880
mformat -f 1440 -i floppy.img ::
mcopy -i floppy.img build/stage2.bin ::/stage2.bin
dd if=build/boot.bin of=floppy.img conv=notrunc
```

Running and debugging in QEMU
-----------------------------

Run the image with QEMU:
```
qemu-system-i386 -drive format=raw,file=floppy.img -serial mon:stdio
```

For GDB debugging, build stage2 and kernel with symbols and use `-s -S` and `-gdb tcp::1234` or `-S -gdb` options:
```
qemu-system-i386 -drive format=raw,file=floppy.img -gdb tcp::1234 -S
# then connect from gdb-multiarch or gdb with appropriate objfiles
```

Practical tips for debugging
- Start simple: get a 512-byte boot sector to print a message first
- Use a serial port for kernel logs (`-serial stdio`) to capture early output
- Use LEDs (emulation) or screen messages to indicate progress steps
- Add deliberate pauses (infinite loops) to attach GDB at stable points

Common pitfalls and how to avoid them
- Not preserving the 0x55AA signature — image won't boot
- Overwriting the BIOS parameter block (BPB) when using filesystem-based stage2 — ensure stage2 is placed as a file and stage1 loads it by reading sectors according to filesystem
- Failing to enable A20 when the kernel expects >1MB memory
- Incorrect GDT entries or forgetting segment register setup after switching to protected mode
- Mistmatching calling conventions between assembly stub and C `main()`

Extending Nyx: next milestones
- Add multiboot header support to load multiboot-compliant kernels
- Implement bzImage loader: detect Linux vmlinuz, relocate, set boot params, load initrd
- Add optional UEFI target (separate build path)
- Add signature checks / simple verification for kernel images

Resources & further reading
- OSDev Wiki: https://wiki.osdev.org/ — essential references
- The Little Book about OS Development: https://littleosbook.github.io/
- Boot sector tutorials and BIOS interrupt references

Where to start in this repository
---------------------------------
- Read `src/bootloader/bootloader.asm` to understand the minimal stage1 and how it loads stage2
- Inspect `src/bootloader/disk.asm` for BIOS disk-read wrappers and retry logic
- Inspect `src/kernel_c/kernel_entry.asm` and `src/kernel_c/kernel.c` to learn how the kernel is linked and entered

If you want, I can:
- Run the current Makefile and try a QEMU boot in this workspace
- Add more annotated code snippets in the files themselves for teaching purposes
- Convert some comments into in-source tutorials near the functions they explain

Enjoy exploring and extending Nyx — bootloaders are small but fascinating systems-level programs that teach a lot about how machines really work.

---
*This README is now a developer-oriented blog and guide. For quick reference, the bootloader and kernel source live in the `src/` tree.*


## Contributing

While this is primarily a learning project, contributions are welcome! Areas where help is appreciated:

- Documentation improvements
- Bug fixes
- Driver development
- Testing on real hardware
- Code review and suggestions

Please open an issue before starting major work to discuss your ideas.


## Acknowledgments

- The OSDev community for invaluable resources
- QEMU developers for an excellent emulator
- Everyone who shares OS development knowledge freely

---


