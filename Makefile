
.PHONY: all run clean

BUILD_DIR := build
SRC_DIR   := src/bootloader

NASM := nasm
QEMU := qemu-system-i386

# Default: build the boot sector
all: $(BUILD_DIR)/mbr.bin

# Assemble the flat 512-byte boot sector
$(BUILD_DIR)/mbr.bin: $(SRC_DIR)/mbr.asm
	mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

# Boot it in QEMU (raw disk image; sector 0 is our boot sector)
run: $(BUILD_DIR)/mbr.bin
	$(QEMU) -drive format=raw,file=$(BUILD_DIR)/mbr.bin

clean:
	rm -rf $(BUILD_DIR)
