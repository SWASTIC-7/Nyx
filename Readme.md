# JazzOS 🎵

A custom x86 operating system built from scratch, starting with a basic bootloader and evolving into a fully-featured OS.

## Current Status

Right now, JazzOS is in its early stages with a basic bootloader that successfully loads and executes a simple kernel. The bootloader uses FAT12 filesystem to load the kernel from a floppy disk image.

### What Works
- ✅ Custom bootloader written in x86 assembly
- ✅ Kernel loading from FAT12 filesystem
- ✅ Basic boot process
- ✅ QEMU emulation support

## Roadmap

This project is just getting started! Here's what's planned:

### Phase 1: Input/Output
- [ ] Keyboard driver and input handling
- [ ] Improved text mode output
- [ ] Basic command line interface

### Phase 2: Boot Experience
- [ ] GRUB integration for multi-boot support
- [ ] Custom boot splash screen
- [ ] Boot configuration options

### Phase 3: Core Features
- [ ] Memory management
- [ ] Interrupt handling system
- [ ] Basic filesystem support
- [ ] Process management

### Phase 4: Advanced Features
- [ ] VGA graphics mode
- [ ] Mouse support
- [ ] Simple shell/terminal
- [ ] User programs support

## Building and Running

### Prerequisites
- NASM assembler
- QEMU emulator
- mtools (for FAT filesystem operations)
- Make

### Quick Start

```bash
# Build and run in QEMU
make run

# Just build the floppy image
make floppy_img

# Clean build artifacts
make clean
```

## Project Structure

```
.
├── src/
│   ├── bootloader/
│   │   └── bootloader.asm    # First stage bootloader
│   └── kernel/
│       └── main.asm          # Kernel entry point
├── build/                     # Build output directory
├── Makefile                   # Build system
└── Readme.md                  # You are here!
```

## Technical Details

- **Target Architecture**: x86 (32-bit)
- **Bootloader**: Custom FAT12 bootloader
- **Filesystem**: FAT12 (for now)
- **Assembly**: NASM syntax

## Learning Resources

This project is a learning journey into OS development. Some helpful resources:

- [OSDev Wiki](https://wiki.osdev.org/)
- Intel x86 Architecture Manuals
- [Writing a Simple Operating System from Scratch](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf)

## Contributing

This is a personal learning project, but feel free to fork it and experiment! If you find bugs or have suggestions, open an issue.

## License

This project is open source and available for educational purposes.

---

*Note: This is an educational project and not intended for production use. It's all about learning how operating systems work at the lowest level!*
