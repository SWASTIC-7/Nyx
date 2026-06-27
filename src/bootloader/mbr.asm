
bits 16                         ; CPU boots in 16-bit real mode
org  0x7C00                     ; BIOS loaded us here; labels are absolute @ 0x7Cxx

start:
    cli                         ; no IRQs while the stack is half-built
                                ; initialization
    xor ax, ax                  ; AX = 0
    mov ds, ax                  ; DS = 0  
    mov es, ax                  ; ES = 0
    mov ss, ax                  ; SS = 0
    mov sp, 0x7C00              ; stack grows DOWN from 0x7C00 into free RAM
    sti                         ; stack valid -> IRQs back on

    cld                         ; DF=0 -> LODSB advances SI forward
    mov si, msg_hello
    call print_string

.hang:                          ; nothing left to do - stop cleanly
    hlt
    jmp .hang

print_string:
    push ax
    push bx
    push si
    mov  bh, 0                  ; video page 0
.next:
    lodsb                       ; AL = [DS:SI]; SI = SI + 1
    test al, al                 ; hit the 0 terminator?
    jz   .done
    mov  ah, 0x0E              ; BIOS teletype output
    int  0x10                  ; print AL, advance cursor
    jmp  .next
.done:
    pop  si
    pop  bx
    pop  ax
    ret

; ---- Data ------------------------------------------------------------------
msg_hello: db 'Hello, NYX user!', 0x0D, 0x0A, 0   ; padded with 0x0D and 0x0A to tell where to stop

; ---- Boot signature --------------------------------------------------------
times 510-($-$$) db 0          ; pad with zeros up to byte 510
dw 0xAA55                       ; bytes 55 AA at offsets 510,511 (little-endian)
