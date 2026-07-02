bits 16
org 0x7C00

STAGE2_LBA     equ 1
STAGE2_SECTORS equ 16
STAGE2_ADDR    equ 0x7E00

P1_START       equ 2048         ; partition 1 start (LBA), 40 MB
P1_SECTORS     equ 81920
P2_START       equ 2048 + 81920 ; partition 2 start (right after P1)
P2_SECTORS     equ 81920

%ifndef FAT32
    jmp short start
    nop

bpb_oem:                db 'NYXOS1.0'
bpb_bytes_per_sector:   dw 512
bpb_sectors_per_cluster:db 1
bpb_reserved_sectors:   dw 17
bpb_num_fats:           db 2
bpb_root_entries:       dw 224
bpb_total_sectors:      dw 2880
bpb_media:              db 0xF0
bpb_sectors_per_fat:    dw 9
bpb_sectors_per_track:  dw 0            ; CHS geometry - unused (LBA only)
bpb_heads:              dw 0            ; CHS geometry - unused (LBA only)
bpb_hidden_sectors:     dd 0
bpb_large_sectors:      dd 0
ebr_drive:              db 0
ebr_reserved:           db 0
ebr_signature:          db 0x29
ebr_volid:              dd 0x12345678
ebr_vollabel:           db 'NYX OS     '
ebr_sysid:              db 'FAT12   '
%endif

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [drive], dl

    cld
    mov si, msg_boot
    call print_string

    mov ah, 0x41                ; int 13h extensions installation check
    mov bx, 0x55AA
    mov dl, [drive]
    int 0x13
    jc  no_lba
    cmp bx, 0xAA55
    jne no_lba

    mov ah, 0x42                ; extended read of stage2 via the DAP
    mov dl, [drive]
    mov si, dap
    int 0x13
    jc  disk_error

    mov dl, [drive]
    jmp 0x0000:STAGE2_ADDR

no_lba:
    mov si, msg_nolba
    call print_string
    jmp halt

disk_error:
    mov si, msg_diskerr
    call print_string

halt:
    cli
    hlt
    jmp halt

print_string:
    push ax
    push bx
    push si
    mov bh, 0
.next:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    pop si
    pop bx
    pop ax
    ret

drive: db 0

dap:
    db 0x10
    db 0
    dw STAGE2_SECTORS
    dw STAGE2_ADDR
    dw 0x0000
    dq STAGE2_LBA

msg_boot:    db 'Nyx: loading stage2...', 0x0D, 0x0A, 0
msg_nolba:   db 'No int13h LBA ext', 0x0D, 0x0A, 0
msg_diskerr: db 'Disk read error', 0x0D, 0x0A, 0

%ifdef FAT32
    times 0x1BE-($-$$) db 0      ; pad up to the partition table
    db 0x80, 0x00, 0x00, 0x00    ; partition 1: active, CHS start (unused)
    db 0x0C, 0x00, 0x00, 0x00    ; type 0x0C = FAT32 LBA, CHS end (unused)
    dd P1_START
    dd P1_SECTORS
    db 0x00, 0x00, 0x00, 0x00    ; partition 2: inactive
    db 0x0C, 0x00, 0x00, 0x00    ; type 0x0C = FAT32 LBA
    dd P2_START
    dd P2_SECTORS
    times 32 db 0                ; partition entries 3-4 (empty)
%else
    times 510-($-$$) db 0
%endif
dw 0xAA55
