; This is used to print strings to the screen using BIOS interrupts
print:
    push si
    push ax
    push bx

.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

print_hex:
    push ax
    push bx
    push cx
    
    mov cx, 4
.loop:
    rol ax, 4
    push ax
    and al, 0x0F
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .print
.digit:
    add al, '0'
.print:
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    pop ax
    loop .loop
    
    pop cx
    pop bx
    pop ax
    ret