; filepath: /home/nazr/Desktop/projects/x86_boot/src/kernel/kernel_entry.asm
[bits 16]
[extern kernel_main]

global _start

_start:
    ; Debug - print 'E' to show entry point reached
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    
    ; Clear interrupts during setup
    cli
    
    ; Setup segments - we're loaded at 0x2000:0x0
    mov ax, 0x2000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF
    
    ; Re-enable interrupts
    sti
    
    ; Debug - print 'C' before calling C code
    mov ah, 0x0E
    mov al, 'C'
    int 0x10
    
    ; Call C kernel
    call kernel_main
    
    ; Should never reach here
    cli
    hlt
    jmp $