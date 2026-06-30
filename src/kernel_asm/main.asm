bits 16
org 0x0

start:
    mov ax, 0x1000              ; we are loaded at 0x1000:0000
    mov ds, ax
    mov es, ax

    mov ah, 0x0E
    mov al, 'K'
    int 0x10

    mov si, msg_p1             ; lives in 1st cluster (file offset 0..511)
    call print
    mov si, msg_p2             ; lives in 2nd cluster (offset 512)
    call print
    mov si, msg_p3             ; lives in 3rd cluster (offset 1024)
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

msg_p1: db 0x0D, 0x0A, 'Part 1 - FAT cluster 2 @ LBA 49', 0x0D, 0x0A, 0

times 512-($-$$) db 0xAA        ; pad to the 2nd cluster boundary
msg_p2: db 'Part 2 - FAT cluster 3 @ LBA 50', 0x0D, 0x0A, 0

times 1024-($-$$) db 0xBB       ; pad to the 3rd cluster boundary
msg_p3: db 'Part 3 - FAT cluster 4 @ LBA 51 - chain works!', 0x0D, 0x0A, 0

times 1536-($-$$) db 0          ; file is exactly 3 clusters
