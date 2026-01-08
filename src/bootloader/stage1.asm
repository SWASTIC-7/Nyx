; ============================================================================
; STAGE 1 BOOTLOADER - Boot Sector (512 bytes)
; ============================================================================
; Loads Stage 2 from sector 1 (right after boot sector) to 0x7E00
; ============================================================================

[bits 16]
[org 0x7C00]

STAGE2_SECTOR equ 1             ; Stage 2 starts at sector 1 (LBA)
STAGE2_SECTORS equ 16           ; 16 sectors = 8KB

jmp short start
nop

; ============================================================================
; BIOS Parameter Block (BPB) - Keep for compatibility
; ============================================================================
bdb_oem:                    db 'NYXOS   '
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 17                   ; Reserve sectors for stage2
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 224
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0xF0
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; Extended Boot Record (EBR)
ebr_drive_number:           db 0
ebr_reserved:               db 0
ebr_signature:              db 0x29
ebr_volume_id:              db 0x12, 0x34, 0x56, 0x78
ebr_volume_label:           db 'NYX OS     '
ebr_system_id:              db 'FAT12   '

; ============================================================================
; Stage 1 Entry Point
; ============================================================================
start:
    ; Debug: print 'A'
    mov ah, 0x0E
    mov al, 'A'
    int 0x10

    ; Setup segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Debug: print 'B'
    mov ah, 0x0E
    mov al, 'B'
    int 0x10

    ; Save boot drive
    mov [ebr_drive_number], dl

    ; Print boot message
    mov si, msg_booting
    call print_string

    mov si, msg_loading
    call print_string

    ; Debug: print 'C'
    mov ah, 0x0E
    mov al, 'C'
    int 0x10

    ; Reset disk
    xor ax, ax
    mov dl, [ebr_drive_number]
    int 0x13
    jc disk_error

    ; Debug: print 'D'
    mov ah, 0x0E
    mov al, 'D'
    int 0x10

    ; Load Stage 2: Read sector 1 onwards to 0x7E00
    ; Debug: print '1' before read
    mov ah, 0x0E
    mov al, '1'
    int 0x10

    ; Set up for disk read - all params at once, no interruptions
    xor ax, ax
    mov es, ax                  ; ES = 0
    mov bx, 0x7E00              ; ES:BX = 0000:7E00
    mov ah, 0x02                ; Read sectors function
    mov al, 16                  ; Read 16 sectors (8KB)
    mov ch, 0                   ; Cylinder 0
    mov cl, 2                   ; Sector 2 (LBA 1)
    mov dh, 0                   ; Head 0
    mov dl, 0                   ; Drive 0 (floppy A:)
    int 0x13
    jc disk_error

    ; Debug: print '2' - read succeeded
    mov ah, 0x0E
    mov al, '2'
    int 0x10

    mov si, msg_ok
    call print_string

    ; Debug: print 'F' before jump
    mov ah, 0x0E
    mov al, 'F'
    int 0x10

    ; Jump to Stage 2
    mov dl, [ebr_drive_number]
    jmp 0x0000:0x7E00

disk_error:
    mov si, msg_disk_error
    call print_string
halt:
    cli
    hlt
    jmp halt

; ============================================================================
; Print String
; ============================================================================
print_string:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    popa
    ret

; ============================================================================
; Data
; ============================================================================
msg_booting:    db 'Nyx v1.0', 0x0D, 0x0A, 0
msg_loading:    db 'Loading...', 0
msg_ok:         db 'OK', 0x0D, 0x0A, 0
msg_disk_error: db 'DISK ERR', 0x0D, 0x0A, 0

; ============================================================================
; Boot Signature
; ============================================================================
times 510-($-$$) db 0
dw 0xAA55
