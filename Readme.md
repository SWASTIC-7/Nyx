# JazzOS 🎵
### A Dark-Themed x86 Operating System from Scratch

A custom x86 operating system built entirely from the ground up, featuring a sleek dark bootloader interface and evolving into a fully-featured operating system. This isn't just a toy project—it's designed to become a real, functional OS.

## Current Status

JazzOS is currently in active development with a working bootloader that loads and executes a custom kernel. The bootloader features a dark, modern interface with loading animations and status messages.

### What Works
- ✅ Custom dark-themed bootloader with visual feedback
- ✅ FAT12 filesystem driver for kernel loading
- ✅ Protected mode transition (16-bit → 32-bit)
- ✅ Kernel loading and execution
- ✅ Basic memory detection
- ✅ QEMU and real hardware support

## Vision

JazzOS aims to be a modern, lightweight operating system with:
- **Dark aesthetic**: Beautiful dark UI throughout the entire system
- **Performance**: Written in assembly and C for maximum efficiency
- **Learning**: Fully documented for educational purposes
- **Real hardware support**: Not just an emulator toy

## Roadmap

### Phase 1: Foundation ⚡ (In Progress)
- [x] Stage 1 bootloader (512 bytes)
- [x] FAT12 filesystem reader
- [ ] Stage 2 bootloader with advanced features
- [ ] A20 line enabling
- [ ] Protected mode with GDT setup
- [ ] Higher-half kernel loading
- [ ] Basic VGA text mode driver with dark theme

### Phase 2: Kernel Core 🔥
- [ ] Interrupt Descriptor Table (IDT) setup
- [ ] Programmable Interrupt Controller (PIC) configuration
- [ ] Keyboard driver with full scancode support
- [ ] Physical memory manager (PMM)
- [ ] Virtual memory manager (VMM) with paging
- [ ] Heap allocator (malloc/free)
- [ ] Multi-tasking scheduler
- [ ] System call interface

### Phase 3: Drivers & I/O 🎮
- [ ] PS/2 mouse driver
- [ ] PIT (Programmable Interval Timer) for timing
- [ ] RTC (Real-Time Clock) driver
- [ ] ATA/IDE hard disk driver
- [ ] Serial port driver for debugging
- [ ] VESA VBE graphics mode
- [ ] Framebuffer console

### Phase 4: Filesystem & Storage 💾
- [ ] Virtual File System (VFS) layer
- [ ] FAT32 filesystem support
- [ ] ext2 filesystem support (read)
- [ ] RAM disk support
- [ ] File operations (open, read, write, close)
- [ ] Directory operations

### Phase 5: User Space 👤
- [ ] ELF binary loader
- [ ] User mode execution
- [ ] Process management
- [ ] Standard C library port
- [ ] Shell (JazzSH) with dark theme
- [ ] Basic Unix-like commands (ls, cat, echo, etc.)
- [ ] Text editor

### Phase 6: Advanced Features 🚀
- [ ] Networking stack (TCP/IP)
- [ ] Sound driver (AC'97/HDA)
- [ ] USB support
- [ ] Multi-core support (SMP)
- [ ] GUI window manager with dark theme
- [ ] Package manager
- [ ] Scripting language interpreter

### Phase 7: Polish & Distribution 💎
- [ ] Boot splash screen with logo
- [ ] Multiple boot options (safe mode, recovery)
- [ ] System configuration tools
- [ ] Installer for real hardware
- [ ] Live USB support
- [ ] Documentation and man pages

## Building and Running

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt install nasm qemu-system-x86 mtools make gcc

# Arch Linux
sudo pacman -S nasm qemu mtools make gcc

# macOS (with Homebrew)
brew install nasm qemu mtools make gcc
```

### Quick Start

```bash
# Build and run in QEMU
make run

# Build with debug symbols
make debug

# Run with GDB debugging
make run-debug

# Just build the floppy image
make floppy_img

# Create bootable USB (Linux only - be careful!)
make usb DEVICE=/dev/sdX

# Clean build artifacts
make clean
```

### QEMU Options

```bash
# Run with serial output for debugging
qemu-system-x86_64 -fda build/main.img -serial stdio

# Run with more memory
qemu-system-x86_64 -fda build/main.img -m 128M

# Boot from hard disk image (future)
qemu-system-x86_64 -hda build/jazzos.img
```

## Project Structure

```
.
├── src/
│   ├── bootloader/
│   │   ├── stage1/
│   │   │   └── boot.asm           # First stage bootloader (512 bytes)
│   │   ├── stage2/
│   │   │   ├── boot2.asm          # Second stage bootloader
│   │   │   ├── fat12.asm          # FAT12 driver
│   │   │   └── a20.asm            # A20 line enabler
│   │   └── bootloader.asm         # Main bootloader (current)
│   ├── kernel/
│   │   ├── arch/x86/
│   │   │   ├── boot.asm          # JazzOS 🎵
### A Custom x86 Operating System from Scratch

A unique x86 operating system built entirely from the ground up, featuring a custom bootloader interface and evolving into a fully-featured operating system. This project aims to create a real, functional OS for learning and experimentation.

## Current Status

JazzOS is currently in active development with a working bootloader that loads and executes a custom kernel. The bootloader features a simple interface with essential status messages.

### What Works
- ✅ Custom bootloader with basic visual feedback
- ✅ FAT12 filesystem driver for kernel loading
- ✅ Protected mode transition (16-bit → 32-bit)
- ✅ Kernel loading and execution
- ✅ Basic memory detection
- ✅ QEMU and real hardware support

## Vision

JazzOS aims to be a modern, lightweight operating system with:
- **Simplicity**: Clean and understandable codebase
- **Performance**: Written in assembly and C for efficiency
- **Learning**: Fully documented for educational purposes
- **Real hardware support**: Functional on actual x86 machines

## Roadmap

### Phase 1: Foundation ⚡ (In Progress)
- [x] Stage 1 bootloader (512 bytes)
- [x] FAT12 filesystem reader
- [ ] Stage 2 bootloader with advanced features
- [ ] A20 line enabling
- [ ] Protected mode with GDT setup
- [ ] Higher-half kernel loading
- [ ] Basic VGA text mode driver

### Phase 2: Kernel Core 🔥
- [ ] Interrupt Descriptor Table (IDT) setup
- [ ] Programmable Interrupt Controller (PIC) configuration
- [ ] Keyboard driver with full scancode support
- [ ] Physical memory manager (PMM)
- [ ] Virtual memory manager (VMM) with paging
- [ ] Heap allocator (malloc/free)
- [ ] Multi-tasking scheduler
- [ ] System call interface

### Phase 3: Drivers & I/O 🎮
- [ ] PS/2 mouse driver
- [ ] PIT (Programmable Interval Timer) for timing
- [ ] RTC (Real-Time Clock) driver
- [ ] ATA/IDE hard disk driver
- [ ] Serial port driver for debugging
- [ ] VESA VBE graphics mode
- [ ] Framebuffer console

### Phase 4: Filesystem & Storage 💾
- [ ] Virtual File System (VFS) layer
- [ ] FAT32 filesystem support
- [ ] ext2 filesystem support (read)
- [ ] RAM disk support
- [ ] File operations (open, read, write, close)
- [ ] Directory operations

### Phase 5: User Space 👤
- [ ] ELF binary loader
- [ ] User mode execution
- [ ] Process management
- [ ] Standard C library port
- [ ] Shell (JazzSH)
- [ ] Basic Unix-like commands (ls, cat, echo, etc.)
- [ ] Text editor

### Phase 6: Advanced Features 🚀
- [ ] Networking stack (TCP/IP)
- [ ] Sound driver (AC'97/HDA)
- [ ] USB support
- [ ] Multi-core support (SMP)
- [ ] GUI window manager
- [ ] Package manager
- [ ] Scripting language interpreter

### Phase 7: Polish & Distribution 💎
- [ ] Boot splash screen with logo
- [ ] Multiple boot options (safe mode, recovery)
- [ ] System configuration tools
- [ ] Installer for real hardware
- [ ] Live USB support
- [ ] Documentation and man pages

## Building and Running

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt install nasm qemu-system-x86 mtools make gcc

# Arch Linux
sudo pacman -S nasm qemu mtools make gcc

# macOS (with Homebrew)
brew install nasm qemu mtools make gcc
```

### Quick Start

```bash
# Build and run in QEMU
make run

# Build with debug symbols
make debug

# Run with GDB debugging
make run-debug

# Just build the floppy image
make floppy_img

# Create bootable USB (Linux only - be careful!)
make usb DEVICE=/dev/sdX

# Clean build artifacts
make clean
```

### QEMU Options

```bash
# Run with serial output for debugging
qemu-system-x86_64 -fda build/main.img -serial stdio

# Run with more memory
qemu-system-x86_64 -fda build/main.img -m 128M

# Boot from hard disk image (future)
qemu-system-x86_64 -hda build/jazzos.img
```

## Project Structure

```
.
├── src/
│   ├── bootloader/
│   │   ├── stage1/
│   │   │   └── boot.asm           # First stage bootloader (512 bytes)
│   │   ├── stage2/
│   │   │   ├── boot2.asm          # Second stage bootloader
│   │   │   ├── fat12.asm          # FAT12 driver
│   │   │   └── a20.asm            # A20 line enabler
│   │   └── bootloader.asm         # Main bootloader (current)
│   ├── kernel/
│   │   ├── arch/x86/
│   │   │   ├── boot.asm           # Kernel entry point
│   │   │   ├── gdt.asm            # Global Descriptor Table
│   │   │   ├── idt.asm            # Interrupt Descriptor Table
│   │   │   └── isr.asm            # Interrupt Service Routines
│   │   ├── drivers/
│   │   │   ├── keyboard.c         # Keyboard driver
│   │   │   ├── vga.c              # VGA text mode driver
│   │   │   └── serial.c           # Serial port driver
│   │   ├── mm/
│   │   │   ├── pmm.c              # Physical memory manager
│   │   │   ├── vmm.c              # Virtual memory manager
│   │   │   └── heap.c             # Heap allocator
│   │   ├── kernel.c               # Kernel main
│   │   └── main.asm               # Current kernel entry
│   └── libc/
│       ├── stdio/
│       ├── stdlib/
│       └── string/
├── build/                          # Build output directory
├── include/                        # Header files
├── tools/                          # Build tools and scripts
├── docs/                           # Documentation
├── Makefile                        # Build system
└── Readme.md                       # You are here!
```

## Technical Details

- **Target Architecture**: x86 (32-bit initially, 64-bit planned)
- **Bootloader**: Custom two-stage bootloader
- **Kernel Type**: Monolithic with modular drivers
- **Filesystem**: FAT12/FAT32, ext2 planned
- **Assembly**: NASM syntax
- **Language**: Assembly + C (no C++ to keep it lightweight)
- **Calling Convention**: cdecl
- **Memory Model**: Higher-half kernel (0xC0000000+)

## Design Philosophy

1. **Minimalism**: Only include what's necessary
2. **Performance**: Assembly where it matters, C for maintainability
3. **Simplicity**: Clear and understandable code
4. **Education**: Well-commented and documented code
5. **Real Hardware**: Designed to run on actual x86 machines

## Screenshots

*Coming soon! We'll add screenshots of the boot process, kernel messages, and shell once the GUI is implemented.*

## Testing on Real Hardware

⚠️ **Warning**: Testing on real hardware can be dangerous. Always backup your data!

```bash
# Create bootable USB (Linux)
sudo dd if=build/main.img of=/dev/sdX bs=512

# On Windows, use Rufus or Win32DiskImager
```

## Development

### Debug Build
```bash
make debug
qemu-system-x86_64 -fda build/main.img -s -S &
gdb -ex "target remote localhost:1234" -ex "symbol-file build/kernel.elf"
```

### Code Style
- Assembly: 4-space indentation, lowercase mnemonics
- C: K&R style, 4-space indentation
- Comments: Explain the "why", not the "what"

## Learning Resources

Essential reading for OS development:

- [OSDev Wiki](https://wiki.osdev.org/) - The Bible of OS development
- [Intel Software Developer Manuals](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [AMD64 Architecture Programmer's Manual](https://www.amd.com/en/support/tech-docs)
- [Writing a Simple Operating System from Scratch](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf) by Nick Blundell
- [The little book about OS development](https://littleosbook.github.io/)
- [Bran's Kernel Development Tutorial](http://www.osdever.net/bkerndev/Docs/intro.htm)

## Contributing

While this is primarily a learning project, contributions are welcome! Areas where help is appreciated:

- Documentation improvements
- Bug fixes
- Driver development
- Testing on real hardware
- Code review and suggestions

Please open an issue before starting major work to discuss your ideas.

## License

This project is open source and available under the MIT License for educational purposes.

## Acknowledgments

- The OSDev community for invaluable resources
- QEMU developers for an excellent emulator
- Everyone who shares OS development knowledge freely

---

**Project Status**: 🚧 Active Development | **Latest Version**: 0.1.0-alpha

*JazzOS - A Journey into Operating System Development.* 🎵
