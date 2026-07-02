bits 16
org 0

%ifdef KB
%define KID 'B'
%else
%define KID 'A'
%endif

start:
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    mov si, msg1               ; lives in cluster 1 (offset 0..511)
    call print
    mov si, msg2               ; lives in cluster 2 (offset 512)
    call print

    cli
    hlt
    jmp $

print:
    push ax
    push bx
    push si
    mov bh, 0
.l:
    lodsb
    or al, al
    jz .d
    mov ah, 0x0E
    int 0x10
    jmp .l
.d:
    pop si
    pop bx
    pop ax
    ret

msg1: db 0x0D, 0x0A, 'Kernel ', KID, ' - Part 1 (cluster 1)', 0x0D, 0x0A, 0
times 512-($-$$) db 0xAA        ; pad to the 2nd cluster boundary
msg2: db 'Kernel ', KID, ' - Part 2 (cluster 2) - 2-cluster chain!', 0x0D, 0x0A, 0
times 1024-($-$$) db 0          ; file is exactly 2 clusters
