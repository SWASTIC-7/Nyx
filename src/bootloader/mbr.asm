bits 16
org 0x7C00

STAGE2_LBA     equ 1
STAGE2_SECTORS equ 16
STAGE2_ADDR    equ 0x7E00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [drive], dl             ; BIOS passes the boot drive in DL

    cld
    mov si, msg_boot
    call print_string

    mov ah, 0x41                ; int 13h extensions installation check
    mov bx, 0x55AA
    mov dl, [drive]
    int 0x13
    jc  no_lba
    cmp bx, 0xAA55              ; compliant BIOS swaps 55AA -> AA55
    jne no_lba

    mov ah, 0x42                ; extended read; params come from the DAP
    mov dl, [drive]
    mov si, dap
    int 0x13
    jc  disk_error

    mov dl, [drive]             ; hand the boot drive to stage2
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
    db 0x10                     ; DAP size
    db 0
    dw STAGE2_SECTORS           ; sectors to read
    dw STAGE2_ADDR              ; buffer offset
    dw 0x0000                   ; buffer segment
    dq STAGE2_LBA              ; 64-bit starting LBA

msg_boot:    db 'Nyx: loading stage2...', 0x0D, 0x0A, 0
msg_nolba:   db 'No int13h LBA ext', 0x0D, 0x0A, 0
msg_diskerr: db 'Disk read error', 0x0D, 0x0A, 0

times 510-($-$$) db 0
dw 0xAA55
