; Second-stage bootloader - loaded at 0x7E00
org 0x7E00
bits 16

; Reference BPB data from boot sector still at 0x7C00
bdb_oem: equ 0x7C03
bdb_bytes_per_sector: equ 0x7C0B
bdb_sectors_per_cluster: equ 0x7C0D
bdb_reserved_sectors: equ 0x7C0E
bdb_fat_count: equ 0x7C10
bdb_dir_entires_count: equ 0x7C11
bdb_total_sectors: equ 0x7C13
bdb_media_descriptor_type: equ 0x7C15
bdb_sectors_per_fat: equ 0x7C16
bdb_sectors_per_track: equ 0x7C18
bdb_heads: equ 0x7C1A
bdb_hidden_sectors: equ 0x7C1C
bdb_large_sector_count: equ 0x7C20

ebr_drive_number: equ 0x7C24
ebr_reserved: equ 0x7C25
ebr_signature: equ 0x7C26
ebr_volume_id: equ 0x7C27
ebr_volume_label: equ 0x7C2B
ebr_system_id: equ 0x7C36

fat32_sectors_per_fat: equ 0x7C24
fat32_flags: equ 0x7C28
fat32_version: equ 0x7C2A
fat32_root_cluster: equ 0x7C2C
fat32_fsinfo: equ 0x7C30
fat32_backup_boot: equ 0x7C32

filesystem_type: equ 0x7C00 + 510 - 3  ; Just before boot signature

start:
    ; Very first thing - prove we're here
    mov ax, 0x0E00 + '!'
    int 0x10
    
    ; Direct character output to prove we got here
    mov ah, 0x0E
    mov al, '2'
    int 0x10
    
    ; Setup segments properly
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    mov al, 'A'
    int 0x10
    
    ; Print second stage message
    mov si, stage2_msg
    call print
    
    mov ah, 0x0E
    mov al, 'B'
    int 0x10
    
    ; Skip serial init for now - causes issues
    ; call serial_init
    ; mov byte [debug_enabled], 1
    
    ; mov si, serial_init_msg
    ; call print
    
    mov ah, 0x0E
    mov al, 'C'
    int 0x10
    
    ; Detect filesystem and load kernel
    mov al, [filesystem_type]
    
    mov ah, 0x0E
    mov al, 'D'
    int 0x10
    
    cmp al, 32
    je load_fat32_kernel
    
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    
    ; Default to FAT12
    jmp load_fat12_kernel

load_fat12_kernel:
    mov ah, 0x0E
    mov al, 'F'
    int 0x10
    
    mov si, fat12_msg
    call print
    
    mov ah, 0x0E
    mov al, 'G'
    int 0x10
    
    ; Hardcoded FAT12 layout for mkfs.fat -F 12 -R 11:
    ; Reserved: 11 sectors
    ; FAT1: 9 sectors (sectors 11-19)
    ; FAT2: 9 sectors (sectors 20-28)
    ; Root dir: 14 sectors (sectors 29-42)
    ; Data area starts at sector 43
    
    ; Read root directory (14 sectors starting at LBA 29)
    mov bx, buffer
    mov ax, 29
    mov cx, 14
    
.read_root_loop:
    push ax
    push cx
    push bx
    
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    
    pop bx
    pop cx
    pop ax
    
    add bx, 512
    inc ax
    dec cx
    jnz .read_root_loop

    ; All sectors read
    mov ah, 0x0E
    mov al, 'R'
    int 0x10

    ; Debug: print first 11 chars of first entry
    mov si, buffer
    mov cx, 11
.print_first_entry:
    lodsb
    mov ah, 0x0E
    int 0x10
    loop .print_first_entry
    
    mov al, '|'
    int 0x10

    ; Search for kernel
    xor bx, bx
    mov di, buffer

.search_kernel:
    ; Check for end of directory
    cmp byte [di], 0
    je .kernel_not_found
    
    ; Skip volume labels (attribute 0x08 at offset 11)
    cmp byte [di + 11], 0x08
    je .next_entry
    
    ; Skip deleted entries (first byte 0xE5)
    cmp byte [di], 0xE5
    je .next_entry
    
    mov si, kernel_name
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found_kernel

.next_entry:
    add di, 32
    inc bx
    cmp bx, 224  ; FAT12 root dir has 224 entries
    jl .search_kernel

.kernel_not_found:
    mov ah, 0x0E
    mov al, 'N'
    int 0x10
    
    mov si, kernel_not_found_msg
    call print
    jmp halt

.found_kernel:
    mov si, kernel_found_msg
    call print
    
    mov ax, [di + 26]
    mov [kernel_cluster], ax

    ; Load FAT1 starting at sector 11
    mov ax, 11
    mov bx, buffer
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    ; Load kernel
    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset

.load_kernel_loop:
    mov ax, [kernel_cluster]
    sub ax, 2
    add ax, 43
    
    push es
    push bx
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    pop bx
    pop es
    
    add bx, 512    ; 512 bytes per sector

    ; Get next cluster
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even
    
.odd:
    shr ax, 4
    jmp .next_cluster
    
.even:
    and ax, 0x0FFF

.next_cluster:
    cmp ax, 0x0FF8
    jae .kernel_loaded

    mov [kernel_cluster], ax
    jmp .load_kernel_loop

.kernel_loaded:
    mov si, kernel_loaded_msg
    call print
    
    mov dl, [ebr_drive_number]
    mov ax, kernel_load_segment
    mov ds, ax
    mov es, ax
    jmp kernel_load_segment:kernel_load_offset

load_fat32_kernel:
    mov si, fat32_msg
    call print
    jmp halt

halt:
    hlt
    jmp halt

%include "src/bootloader/disk.asm"
%include "src/bootloader/print.asm"

; Messages
stage2_msg: db "Stage2 loaded", 0x0D, 0x0A, 0
serial_init_msg: db "Serial debug enabled", 0x0D, 0x0A, 0
fat12_msg: db "Loading FAT12 kernel...", 0x0D, 0x0A, 0
fat32_msg: db "Loading FAT32 kernel...", 0x0D, 0x0A, 0
unknown_fs_msg: db "Unknown filesystem!", 0x0D, 0x0A, 0

; Shared data
kernel_name: db "KERNEL  BIN"
kernel_cluster: dw 0
kernel_load_segment: equ 0x2000
kernel_load_offset: equ 0x0000
buffer: equ 0x8000

kernel_not_found_msg: db "KERNEL.BIN not found!", 0x0D, 0x0A, 0
kernel_found_msg: db "Kernel found!", 0x0D, 0x0A, 0
kernel_loaded_msg: db "Kernel loaded, jumping...", 0x0D, 0x0A, 0
