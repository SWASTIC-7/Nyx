; filepath: /home/nazr/Desktop/projects/x86_boot/src/kernel/main.asm
[org 0x0]
[bits 16]

start:
    ; First thing - print something to show we got here
    mov ah, 0x0E
    mov al, 'K'
    int 0x10
    mov al, '!'
    int 0x10
    
    ; Setup segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    
    ; Print kernel message
    mov si, kernel_msg
    call print
    
    ; Print success message
    mov si, success_msg
    call print
    
    ; Halt
    cli
    hlt
    jmp $

; Print string function
print:
    push ax
    push bx
    push si
    
.loop:
    lodsb
    or al, al
    jz .done
    
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .loop
    
.done:
    pop si
    pop bx
    pop ax
    ret

; Data
kernel_msg: db 0x0D, 0x0A, "JazzOS Kernel v0.1", 0x0D, 0x0A, 0
success_msg: db "Kernel loaded successfully!", 0x0D, 0x0A, 0

times 512-($-$$) db 0