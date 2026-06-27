# ============================================================================
# Nyx bootloader - build & run
# Run from the project root inside WSL:  make  |  make run  |  make clean
# ============================================================================
.PHONY: all run clean

BUILD_DIR := build
SRC_DIR   := src/bootloader

NASM := nasm
QEMU := qemu-system-i386

all: $(BUILD_DIR)/disk.img

$(BUILD_DIR)/mbr.bin: $(SRC_DIR)/mbr.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

$(BUILD_DIR)/stage2.bin: $(SRC_DIR)/stage2.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

# Disk image: MBR at LBA 0, stage2 from LBA 1
$(BUILD_DIR)/disk.img: $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/stage2.bin
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	dd if=$(BUILD_DIR)/mbr.bin    of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	dd if=$(BUILD_DIR)/stage2.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null

run: $(BUILD_DIR)/disk.img
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/disk.img

clean:
	rm -rf $(BUILD_DIR)
