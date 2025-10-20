[org 0x1000]     ; must match bootloader’s load address

mov ah, 0x0E
mov al, 'K'
int 0x10
mov al, '!'
int 0x10
jmp $

times 510-($-$$) db 0
dw 0xAA55
