bits 16
org 0x7E00

KERNEL_SEG equ 0x1000

stage2_start:
    mov [drive], dl
    xor ax, ax
    mov ds, ax
    mov es, ax

    cld
    mov si, msg_stage2
    call print_string

    call fat12_load_kernel

    mov si, msg_jump
    call print_string
    jmp KERNEL_SEG:0x0000

; read CX sectors from LBA AX into ES:BX
read_sectors:
    mov [dap_count], cx
    mov [dap_off], bx
    mov [dap_seg], es
    mov [dap_lba], ax
    mov word [dap_lba+2], 0
    mov ah, 0x42
    mov dl, [drive]
    mov si, dap
    int 0x13
    jc .fail
    ret
.fail:
    mov si, msg_diskerr
    call print_string
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

halt:
    cli
    hlt
    jmp halt

drive: db 0

dap:
    db 0x10
    db 0
dap_count: dw 0
dap_off:   dw 0
dap_seg:   dw 0
dap_lba:   dd 0
           dd 0

msg_stage2:  db 'Stage 2 running, loading kernel via FAT12...', 0x0D, 0x0A, 0
msg_jump:    db 'Jumping to kernel...', 0x0D, 0x0A, 0
msg_diskerr: db 'Disk read error', 0x0D, 0x0A, 0

%include "fat12.asm"
