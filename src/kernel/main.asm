org 0x0
bits 16

main:

    mov ax,0
    mov ds,ax
    mov es,ax
    mov ss,ax

    mov sp,0x7C00
    mov si,print_message
    call print
    hlt

halt:
    jmp halt

print:
    push si
    push ax
    push bx

print_loop:
    lodsb
    or al,al
    jz print_done
    mov ah,0x0E
    mov bx,0
    int 0x10
    jmp print_loop

print_done:
    pop bx
    pop ax
    pop si
    ret

print_message: db "This is Swastic's kernel!", 0x0D, 0x0A, 0 

times 510-($-$$) db 0
dw 0xAA55
