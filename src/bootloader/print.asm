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
    ; print hex for AX (4 hex digits) to screen only
    push ax
    push bx
    push cx

    mov cx, 4
.ph_loop:
    rol ax, 4
    push ax
    and al, 0x0F
    cmp al, 10
    jl .ph_digit
    add al, 'A' - 10
    jmp .ph_print
.ph_digit:
    add al, '0'
.ph_print:
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    pop ax
    loop .ph_loop

    pop cx
    pop bx
    pop ax
    ret

; --- Serial debug support ---
serial_init:
    ; Initialize COM1 (0x3F8) for 115200: divisor=1
    mov dx, 0x3F8
    mov al, 0x00
    out dx, al        ; disable interrupts
    mov dx, 0x3FB
    mov al, 0x80
    out dx, al        ; enable DLAB
    mov dx, 0x3F8
    mov al, 0x01
    out dx, al        ; divisor low = 1
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al        ; divisor high = 0
    mov dx, 0x3FB
    mov al, 0x03
    out dx, al        ; 8 bits, no parity, 1 stop bit
    mov dx, 0x3FC
    mov al, 0x03
    out dx, al        ; RTS/DSR set
    ret

serial_write_char:
    ; AL = character to write
    push ax
    mov dx, 0x3FD    ; LSR (base+5)
.sw_wait:
    in al, dx
    test al, 0x20
    jz .sw_wait
    pop ax
    mov dx, 0x3F8
    out dx, al
    ret

serial_print:
    push si
    push ax
    
 .sp_loop:
    lodsb
    or al, al
    jz .sp_done
    push ax
    call serial_write_char
    pop ax
    jmp .sp_loop

.sp_done:
    pop ax
    pop si
    ret

serial_print_hex:
    ; prints AX as 4 hex digits to serial
    push ax
    push cx

    mov cx, 4
.sph_loop:
    rol ax, 4
    push ax
    and al, 0x0F
    cmp al, 10
    jl .sph_digit
    add al, 'A' - 10
    jmp .sph_print
.sph_digit:
    add al, '0'
.sph_print:
    push ax
    call serial_write_char
    pop ax
    pop ax
    loop .sph_loop

    pop cx
    pop ax
    ret

; Temporary helper label used by `print` serial branch
boot_print_ptr: dw 0
boot_temp_string: db 0
debug_enabled: db 0