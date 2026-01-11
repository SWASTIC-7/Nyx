.PHONY: all run clean debug gdb

# Directories
BUILD_DIR = build
SRC_DIR = src

# Tools
NASM = nasm
GCC = gcc
LD = ld
QEMU = qemu-system-i386

# Flags
GCC_FLAGS = -m32 -ffreestanding -fno-pie -nostdlib -c -Wall -Wextra
LD_FLAGS = -m elf_i386 -T $(SRC_DIR)/kernel_c/linker.ld --oformat binary

# Default target
all: $(BUILD_DIR)/main.img

# Run in QEMU
run: $(BUILD_DIR)/main.img
	$(QEMU) -fda $(BUILD_DIR)/main.img

# Debug with GDB
debug: $(BUILD_DIR)/main.img
	$(QEMU) -fda $(BUILD_DIR)/main.img -s -S &
	@echo "QEMU started. Connect GDB with: target remote localhost:1234"

gdb:
	gdb -ex "target remote localhost:1234" -ex "set architecture i8086"

clean:
	rm -rf $(BUILD_DIR)/*

# ============================================================================
# Build Stage 1 Bootloader (512 bytes)
# ============================================================================
$(BUILD_DIR)/stage1.bin: $(SRC_DIR)/bootloader/stage1.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

# ============================================================================
# Build Stage 2 Bootloader
# ============================================================================
$(BUILD_DIR)/stage2.bin: $(SRC_DIR)/bootloader/stage2.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

# ============================================================================
# Build Kernel
# ============================================================================
$(BUILD_DIR)/kernel_entry.o: $(SRC_DIR)/kernel_c/kernel_entry.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) -f elf32 $< -o $@

$(BUILD_DIR)/kernel.o: $(SRC_DIR)/kernel_c/kernel.c
	@mkdir -p $(BUILD_DIR)
	$(GCC) $(GCC_FLAGS) $< -o $@

$(BUILD_DIR)/kernel.bin: $(BUILD_DIR)/kernel_entry.o $(BUILD_DIR)/kernel.o
	$(LD) $(LD_FLAGS) $^ -o $@

# ============================================================================
# Create Floppy Image (simple layout - no FAT)
# ============================================================================
$(BUILD_DIR)/main.img: $(BUILD_DIR)/stage1.bin $(BUILD_DIR)/stage2.bin $(BUILD_DIR)/kernel.bin
	@echo "Creating floppy image..."
	# Create 1.44MB floppy image filled with zeros
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null
	
	# Write stage1 to sector 0 (boot sector)
	dd if=$(BUILD_DIR)/stage1.bin of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	
	# Write stage2 to sector 1 (right after boot sector)
	dd if=$(BUILD_DIR)/stage2.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null
	
	# Write kernel to sector 17 (after stage2's 16 sectors)
	dd if=$(BUILD_DIR)/kernel.bin of=$@ bs=512 seek=17 conv=notrunc 2>/dev/null
	
	@echo ""
	@echo "=== Image Layout ==="
	@echo "  Sector 0:      Stage 1 (512 bytes)"
	@echo "  Sectors 1-16:  Stage 2 (8KB)"
	@echo "  Sectors 17+:   Kernel"