# Nyx
### Advanced Dark-Themed Bootloader

This repository focuses on building an advanced, dark-themed x86 bootloader. The operating system itself will remain intentionally minimal and only provide what is necessary to test the bootloader. The preferred long-term goal is for the bootloader to be able to boot real kernels (for example, Linux bzImage) and to interoperate with standard boot mechanisms (multiboot, GRUB chainloading), rather than to implement a full general-purpose OS.

## Current Status

Nyx is currently in active development with a working bootloader that loads and executes a custom kernel. The bootloader features a dark, modern interface with loading animations and status messages.


## Vision

Nyx aims to be a modern, lightweight operating system with:
- **Dark aesthetic**: Beautiful dark UI throughout the entire system
- **Performance**: Written in assembly and C for maximum efficiency
- **Learning**: Fully documented for educational purposes
- **Real hardware support**: Not just an emulator toy

## Project Focus

Primary objective: bootstrap real kernels reliably and provide a polished, extensible boot experience with a dark UI. The kernel used for functional testing will be minimal (a small, self-contained test kernel) or an upstream Linux kernel (bzImage/initrd) — whichever is most useful for validating bootloader features.

Why this approach:
- Concentrate effort on advanced bootloading: loading, relocating and starting kernels, handling initrd/cmdline, kernel format support.
- Avoid reimplementing a full OS kernel. Keep the in-repo kernel minimal for quick iteration and testing.
- Let existing kernels (Linux) handle higher-level OS functionality when needed.

## Bootloader-features

- Basic Bootloader: robust 512-byte boot sector with FAT12 support and readable UI (done / in progress)
- Advanced Bootloader: larger second-stage bootloader
  - A20 line handling
  - Protected mode switch & GDT setup
  - Advanced disk access (FAT12/32) and partition handling
  - Kernel selection menu with dark-themed UI and animations
- Kernel support & chainloading
  - Multiboot support (load Multiboot-compliant kernels)
  - Direct bzImage support (detect, relocate, decompress, set boot params)
  - Initrd loading and kernel command line passing
  - GRUB/chainload interoperability for complex setups
- Hardware & UX
  - Keyboard input driver for menu interaction
  - Serial console for debugging
  - VGA framebuffer splash (dark theme) and logo
  - Simple theme configuration and fallback modes
- Systems & security
  - Optional UEFI stub / fallback (separate target)
  - Optional secure boot integration for UEFI path
  - Basic checksum / signature verification for kernels and initrd
- Tooling
  - Image builder scripts (place kernels/initrds/menus on images)
  - QEMU-friendly run/debug targets and GDB support
  - Easy way to test Linux kernels (bzImage + initrd) or minimal test kernels

## Minimal OS vs. Linux kernel testing

Two supported testing modes:
- Minimal test kernel: a tiny assembly/C kernel (keeps iteration fast). Useful when developing low-level bootloader features that don't require a full OS.
- Linux kernel (preferred for full validation): the bootloader will aim to load a Linux bzImage and optional initrd, pass kernel cmdline, and boot it. This verifies real-world compatibility.

Testing notes:
- Multiboot kernels are easiest to test during early stages.
- When bzImage support is ready, test with an actual vmlinuz and initramfs to validate kernel params, initrd loading, and module handling.

## Building and Running (updated)

Prerequisites: nasm, qemu-system-x86, mtools, make, a Linux kernel (vmlinuz) if testing bzImage.

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

️ **Warning**: Testing on real hardware can be dangerous. Always backup your data!

## References

References taken to make this project

- [OSDev Wiki](https://wiki.osdev.org/) - The Bible of OS development
- [Writing my own Bootloader](https://dev.to/frosnerd/writing-my-own-boot-loader-3mld) - Medium Article
- [The little book about OS development](https://littleosbook.github.io/)
- [Bran's Kernel Development Tutorial](http://www.osdever.net/bkerndev/Docs/intro.htm)
- [Video Tutorial by OliveStem](https://www.youtube.com/watch?v=yBO-EJoVDo0&list=PL2EF13wm-hWCoj6tUBGUmrkJmH1972dBB)

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


