# ============================================================================
# Nyx bootloader - build & run.  Run from the project root inside WSL.
#   make        build the boot disk
#   make run    boot it in QEMU (menu -> pick NyxOS / NyxOS2 -> splash -> kernel)
#   make test   static image checks + runtime checkpoints
#   make clean
# ============================================================================
.PHONY: all run test clean

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

$(BUILD_DIR)/stage2.bin: $(SRC_DIR)/stage2.asm $(SRC_DIR)/fat12.asm $(SRC_DIR)/fat32.asm $(SRC_DIR)/menu.asm $(SRC_DIR)/gdt.asm $(SRC_DIR)/a20.asm $(SRC_DIR)/e820.asm $(SRC_DIR)/splash.asm $(SRC_DIR)/glyphs.inc
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin -I $(SRC_DIR)/ -DBOOT_PART=$(BOOT_PART) $< -o $@ -l $(BUILD_DIR)/stage2.lst

# The two bootable kernels are Multiboot kernels built from one source
$(BUILD_DIR)/nyxos.bin: $(KSRC_DIR)/mb_kernel.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

$(BUILD_DIR)/nyxos2.bin: $(KSRC_DIR)/mb_kernel.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin -DNYX2 $< -o $@

# FAT12 boot disk: NYX.CFG + both kernels, then install MBR + stage2
$(BUILD_DIR)/disk.img: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/nyxos.bin $(BUILD_DIR)/nyxos2.bin src/nyx.cfg
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	mkfs.fat -F 12 -R 17 -r 224 -s 1 -S 512 -M 0xF0 $@ >/dev/null
	mcopy -i $@ $(BUILD_DIR)/nyxos.bin  ::/NYXOS.BIN
	mcopy -i $@ $(BUILD_DIR)/nyxos2.bin ::/NYXOS2.BIN
	mcopy -i $@ src/nyx.cfg ::/NYX.CFG
	dd if=$(BUILD_DIR)/mbr.bin    of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/stage2.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null

run: $(BUILD_DIR)/disk.img
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/disk.img

test: all
	python3 tests/check_image.py $(BUILD_DIR)/disk.img $(BUILD_DIR)/nyxos.bin 0 "NYXOS   BIN"
	python3 tests/run_checkpoints.py $(BUILD_DIR)/disk.img tests/checkpoints_menu.json

clean:
	rm -rf $(BUILD_DIR)
