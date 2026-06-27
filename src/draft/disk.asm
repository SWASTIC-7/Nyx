; Disk I/O routines

; Convert LBA to CHS
; Input: AX = LBA
; Output: CX, DH = CHS values
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bdb_sectors_per_track]
    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret

; Read sectors from disk
; Input: AX = LBA, CL = sector count, DL = drive, ES:BX = buffer
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    call lba_to_chs
    mov ah, 0x02
    mov di, 3

.retry:
    stc
    int 0x13
    jnc .done

    call disk_reset
    dec di
    test di, di
    jnz .retry

.failed:
    mov si, disk_error_msg
    call print
    jmp halt

.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 0x13
    jc .failed
    popa
    ret
    
.failed:
    mov si, disk_error_msg
    call print
    jmp halt

disk_error_msg: db "Disk error!", 0x0D, 0x0A, 0