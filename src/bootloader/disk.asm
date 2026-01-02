; Disk I/O routines

; Convert LBA to CHS
; Input: AX = LBA
; Output: CX, DH = CHS values (CL = sector, CH = cylinder, DH = head)
lba_to_chs:
    ; Input: AX = LBA
    ; Output: CH = cylinder (low 8 bits)
    ;         CL = sector (1-based)
    ;         DH = head
    ; Preserve registers BX,CX,DX
    push bx
    push cx
    push dx

    mov bx, 18        ; sectors per track
    xor dx, dx
    div bx            ; AX = track, DX = sector-1
    inc dl            ; DL = sector (1-based)
    push dx           ; save sector on stack

    xor dx, dx
    mov bx, 2         ; heads
    div bx            ; AX = cylinder, DX = head

    mov ch, al        ; CH = cylinder (low 8 bits)
    mov dh, dl        ; DH = head

    pop dx            ; restore sector into DX
    mov cl, dl        ; CL = sector

    pop dx            ; restore original DX
    pop cx
    pop bx
    ret

; Read sectors from disk
; Input: AX = LBA, CL = sector count, DL = drive, ES:BX = buffer
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx         ; Save sector count (CL)
    call lba_to_chs ; Returns CH=cylinder, CL=sector, DH=head
                    ; Now CX has CH=cylinder, CL=sector number
    pop ax          ; AL = original sector count
    mov ah, 0x02    ; AH = BIOS read function
    ; Now we need to swap: AL has count, but BIOS needs it in AL
    ; and CL has sector number which is correct
    ; So AX is now ready: AH=02h, AL=sector count
    ; CX has CH=cylinder, CL=sector
    ; DH has head
    ; DL should have drive number (already set)
    
    mov di, 3       ; Retry count

.retry:
    pusha           ; Save all registers before BIOS call
    stc
    int 0x13
    jc .check_retry
    popa            ; Restore on success
    jmp .done

.check_retry:
    popa            ; Restore on failure
    dec di
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