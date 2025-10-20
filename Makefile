.PHONY: floppy_img bootloader kernel run clean

run: floppy_img
	qemu-system-x86_64 -fda build/main.img

clean:
	rm -rf build/*

floppy_img: build/main.img
build/main.img: bootloader kernel
	dd if=/dev/zero of=build/main.img bs=512 count=2880
	mkfs.fat -F 12 -n "JAZZOS" build/main.img 
	dd if=build/bootloader.bin of=build/main.img conv=notrunc
	mcopy -i build/main.img build/kernel.bin "::kernel.bin"


bootloader: build/bootloader.bin
build/bootloader.bin: 
	nasm src/bootloader/bootloader.asm -f bin -o build/bootloader.bin

kernel: build/kernel.bin
build/kernel.bin:
	nasm src/kernel/main.asm -f bin -o build/kernel.bin