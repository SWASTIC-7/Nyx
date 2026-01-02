; filepath: /home/nazr/Desktop/projects/x86_boot/src/bootloader/bootloader.asm
org 0x7C00
bits 16

jmp short main
nop

; BIOS Parameter Block (BPB)
bdb_oem: db  'MSWIN4.1'
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 11
bdb_fat_count: db 2
bdb_dir_entires_count: dw 0E0h
bdb_total_sectors: dw 2880
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sector_count: dd 0

; Extended Boot Record
ebr_drive_number: db 0
ebr_reserved: db 0
ebr_signature: db 0x29
ebr_volume_id: db 12h, 34h, 56h, 78h
ebr_volume_label: db 'JAZZOS     '
ebr_system_id: db 'FAT12   '

; FAT32 Extended Fields
fat32_sectors_per_fat: dd 0
fat32_flags: dw 0
fat32_version: dw 0
fat32_root_cluster: dd 0
fat32_fsinfo: dw 0
fat32_backup_boot: dw 0
fat32_reserved: times 12 db 0

main:
    ; Setup segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    mov [ebr_drive_number], dl
    mov [0x7C00 + 0x24], dl  ; Also save at the BPB location
    
    ; Print boot message
    mov si, boot_message
    call print
    
    ; Detect filesystem type
    call detect_filesystem
    
    ; Load second stage bootloader (multiple sectors)
    mov ax, 1           ; Start at LBA 1 (sector after boot sector)
    mov cl, 10          ; Load 10 sectors (5KB) for stage2
    mov bx, 0x7E00      ; Load to 0x7E00
    mov dl, [ebr_drive_number]
    call disk_read
    
    ; Jump to second stage
    jmp 0x0000:0x7E00

halt:
    hlt
    jmp halt

; Detect filesystem type based on BPB
detect_filesystem:
    mov ax, [bdb_sectors_per_fat]
    test ax, ax
    jz .is_fat32
    
    mov ax, [bdb_total_sectors]
    cmp ax, 0
    jne .is_fat12
    
    mov eax, [bdb_large_sector_count]
    test eax, eax
    jnz .is_fat32
    
.is_fat12:
    mov byte [filesystem_type], 12
    ret
    
.is_fat32:
    mov byte [filesystem_type], 32
    ret

%include "src/bootloader/disk.asm"
%include "src/bootloader/print.asm"

; Data
boot_message: db "NYX", 0x0D, 0x0A, 0
filesystem_type: db 0

times 510-($-$$) db 0
dw 0xAA55