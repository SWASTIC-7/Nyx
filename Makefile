# ============================================================================
# Nyx bootloader - build & run
# Run from the project root inside WSL:  make  |  make run  |  make clean
# ============================================================================
.PHONY: all run clean

BUILD_DIR := build
SRC_DIR   := src/bootloader
KSRC_DIR  := src/kernel_asm

NASM := nasm
QEMU := qemu-system-i386

all: $(BUILD_DIR)/disk.img

$(BUILD_DIR)/mbr.bin: $(SRC_DIR)/mbr.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

$(BUILD_DIR)/stage2.bin: $(SRC_DIR)/stage2.asm $(SRC_DIR)/fat12.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin -I $(SRC_DIR)/ $< -o $@

$(BUILD_DIR)/kernel.bin: $(KSRC_DIR)/main.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

# FAT12 disk: format, copy kernel as a file, install boot sector + stage2
$(BUILD_DIR)/disk.img: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/kernel.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	mkfs.fat -F 12 -R 17 -r 224 -s 1 -S 512 -M 0xF0 $@ >/dev/null
	mcopy -i $@ $(BUILD_DIR)/kernel.bin ::/KERNEL.BIN
	dd if=$(BUILD_DIR)/mbr.bin    of=$@ bs=512 count=1  conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/stage2.bin of=$@ bs=512 seek=1   conv=notrunc 2>/dev/null

run: $(BUILD_DIR)/disk.img
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/disk.img

clean:
	rm -rf $(BUILD_DIR)
