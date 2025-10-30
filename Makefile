.PHONY: floppy_img bootloader kernel kernel_asm kernel_c run clean fat12 fat32

# Default to C kernel with FAT12
run: floppy_img
	qemu-system-x86_64 -fda build/main.img

clean:
	rm -rf build/*

# Default to FAT12 with C kernel
floppy_img: build/main_fat12.img
	cp build/main_fat12.img build/main.img

# FAT12 image
fat12: build/main_fat12.img
build/main_fat12.img: bootloader kernel_c
	dd if=/dev/zero of=build/main_fat12.img bs=512 count=2880
	mkfs.fat -F 12 -n "JAZZOS" build/main_fat12.img
	dd if=build/bootloader.bin of=build/main_fat12.img conv=notrunc
	mcopy -i build/main_fat12.img build/kernel.bin "::kernel.bin"

# FAT32 image (larger, 32MB)
fat32: build/main_fat32.img
build/main_fat32.img: bootloader kernel_c
	dd if=/dev/zero of=build/main_fat32.img bs=1M count=32
	mkfs.fat -F 32 -n "JAZZOS" build/main_fat32.img
	dd if=build/bootloader.bin of=build/main_fat32.img conv=notrunc
	mcopy -i build/main_fat32.img build/kernel.bin "::kernel.bin"

bootloader: build/bootloader.bin
build/bootloader.bin: src/bootloader/bootloader.asm src/bootloader/fat12.asm src/bootloader/fat32.asm src/bootloader/disk.asm src/bootloader/print.asm
	nasm src/bootloader/bootloader.asm -f bin -o build/bootloader.bin

# Assembly kernel (simple)
kernel_asm: build/kernel_asm.bin
build/kernel_asm.bin: src/kernel_asm/main.asm
	nasm src/kernel_asm/main.asm -f bin -o build/kernel_asm.bin

# C kernel
kernel_c: build/kernel.bin
build/kernel.bin: src/kernel_c/kernel_entry.asm src/kernel_c/kernel.c
	nasm src/kernel_c/kernel_entry.asm -f elf -o build/kernel_entry.o
	gcc -m32 -ffreestanding -c src/kernel_c/kernel.c -o build/kernel.o -fno-pie -nostdlib
	ld -m elf_i386 -Ttext 0x20000 --oformat binary -o build/kernel.bin build/kernel_entry.o build/kernel.o

# Legacy target
kernel: kernel_c

# Test with assembly kernel
run-asm: bootloader kernel_asm
	dd if=/dev/zero of=build/main_fat12.img bs=512 count=2880
	mkfs.fat -F 12 -n "JAZZOS" build/main_fat12.img
	dd if=build/bootloader.bin of=build/main_fat12.img conv=notrunc
	mcopy -i build/main_fat12.img build/kernel_asm.bin "::kernel.bin"
	cp build/main_fat12.img build/main.img
	qemu-system-x86_64 -fda build/main.img

# Test with FAT32
run-fat32: fat32
	cp build/main_fat32.img build/main.img
	qemu-system-x86_64 -fda build/main.img

# Debug with GDB
debug: floppy_img
	@echo "target remote localhost:1234" > build/gdbcommands.txt
	@echo "set architecture i8086" >> build/gdbcommands.txt
	@echo "break *0x7c00" >> build/gdbcommands.txt
	@echo "layout asm" >> build/gdbcommands.txt
	@echo "layout regs" >> build/gdbcommands.txt
	qemu-system-x86_64 -fda build/main.img -s -S

# Connect GDB to debugging session
gdb:
	gdb -x build/gdbcommands.txt