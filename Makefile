# ============================================================================
# Nyx bootloader - build & run
# Run from the project root inside WSL:  make  |  make run  |  make clean
# ============================================================================
.PHONY: all run clean test test-fat32 test-menu fat32 run-fat32 menu run-menu

BUILD_DIR := build
SRC_DIR   := src/bootloader
KSRC_DIR  := src/kernel_asm

NASM := nasm
QEMU := qemu-system-i386
BOOT_PART ?= 0

all: $(BUILD_DIR)/disk.img

$(BUILD_DIR)/mbr.bin: $(SRC_DIR)/mbr.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@ -l $(BUILD_DIR)/mbr.lst

$(BUILD_DIR)/stage2.bin: $(SRC_DIR)/stage2.asm $(SRC_DIR)/fat12.asm $(SRC_DIR)/fat32.asm $(SRC_DIR)/menu.asm $(SRC_DIR)/gdt.asm $(SRC_DIR)/a20.asm $(SRC_DIR)/e820.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin -I $(SRC_DIR)/ -DBOOT_PART=$(BOOT_PART) $< -o $@ -l $(BUILD_DIR)/stage2.lst

$(BUILD_DIR)/kernel.bin: $(KSRC_DIR)/main.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

$(BUILD_DIR)/kernel_a.bin: $(KSRC_DIR)/kernel_test.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

$(BUILD_DIR)/kernel_b.bin: $(KSRC_DIR)/kernel_test.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin -DKB $< -o $@

# FAT12 disk: format, copy kernel as a file, install boot sector + stage2
$(BUILD_DIR)/disk.img: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	mkfs.fat -F 12 -R 17 -r 224 -s 1 -S 512 -M 0xF0 $@ >/dev/null
	mcopy -i $@ $(BUILD_DIR)/kernel.bin ::/KERNEL.BIN
	dd if=$(BUILD_DIR)/mbr.bin    of=$@ bs=512 count=1  conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/stage2.bin of=$@ bs=512 seek=1   conv=notrunc 2>/dev/null

run: $(BUILD_DIR)/disk.img
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/disk.img

# ---- FAT32 variant: MBR + partition table, FAT32 partition at LBA 2048 ----
fat32: $(BUILD_DIR)/disk_fat32.img

$(BUILD_DIR)/mbr_fat32.bin: $(SRC_DIR)/mbr.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin -DFAT32 $< -o $@ -l $(BUILD_DIR)/mbr_fat32.lst

$(BUILD_DIR)/disk_fat32.img: $(BUILD_DIR)/mbr_fat32.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/kernel_a.bin $(BUILD_DIR)/kernel_b.bin
	dd if=/dev/zero of=$(BUILD_DIR)/part1.img bs=1M count=40 2>/dev/null
	mkfs.fat -F 32 -s 1 -h 2048 $(BUILD_DIR)/part1.img >/dev/null
	mcopy -i $(BUILD_DIR)/part1.img $(BUILD_DIR)/kernel_a.bin ::/KERNEL.BIN
	dd if=/dev/zero of=$(BUILD_DIR)/part2.img bs=1M count=40 2>/dev/null
	mkfs.fat -F 32 -s 1 -h 83968 $(BUILD_DIR)/part2.img >/dev/null
	mcopy -i $(BUILD_DIR)/part2.img $(BUILD_DIR)/kernel_b.bin ::/KERNEL.BIN
	dd if=/dev/zero of=$@ bs=512 count=165888 2>/dev/null
	dd if=$(BUILD_DIR)/mbr_fat32.bin of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/stage2.bin    of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/part1.img     of=$@ bs=512 seek=2048  conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/part2.img     of=$@ bs=512 seek=83968 conv=notrunc 2>/dev/null

run-fat32: $(BUILD_DIR)/disk_fat32.img
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/disk_fat32.img

# ---- Boot-menu demo: FAT12 disk with NYX.CFG + two kernels ----
menu: $(BUILD_DIR)/disk_menu.img

$(BUILD_DIR)/disk_menu.img: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/kernel_a.bin $(BUILD_DIR)/kernel_b.bin src/nyx.cfg
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	mkfs.fat -F 12 -R 17 -r 224 -s 1 -S 512 -M 0xF0 $@ >/dev/null
	mcopy -i $@ $(BUILD_DIR)/kernel_a.bin ::/KERNELA.BIN
	mcopy -i $@ $(BUILD_DIR)/kernel_b.bin ::/KERNELB.BIN
	mcopy -i $@ src/nyx.cfg ::/NYX.CFG
	dd if=$(BUILD_DIR)/mbr.bin    of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/stage2.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null

run-menu: $(BUILD_DIR)/disk_menu.img
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/disk_menu.img

# Runtime checkpoints for the menu: config read + parsed into the entry table
test-menu: menu
	python3 tests/run_checkpoints.py $(BUILD_DIR)/disk_menu.img tests/checkpoints_menu.json

# Run both test layers: static image checks, then runtime checkpoint checks
test: all
	python3 tests/check_image.py
	python3 tests/run_checkpoints.py

# Static layout checks for both FAT32 partitions
test-fat32: fat32
	python3 tests/check_image.py $(BUILD_DIR)/disk_fat32.img $(BUILD_DIR)/kernel_a.bin 0
	python3 tests/check_image.py $(BUILD_DIR)/disk_fat32.img $(BUILD_DIR)/kernel_b.bin 1

clean:
	rm -rf $(BUILD_DIR)
