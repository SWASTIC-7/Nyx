bits 16
org 0x7E00

stage2_start:
    xor ax, ax
    mov ds, ax

    cld
    mov si, msg_stage2
    call print_string

.hang:
    hlt
    jmp .hang

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

msg_stage2: db 'Stage 2 running at 0x7E00!', 0x0D, 0x0A, 0
