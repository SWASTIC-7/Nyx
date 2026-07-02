; A20 gate - unlock addressing above 1 MB before entering protected mode.
; Try the BIOS method, fall back to fast-A20 (port 0x92), then verify.

enable_a20:
    call check_a20
    jnz .verify                  ; already on (some BIOSes enable it)

    mov ax, 0x2401               ; BIOS: enable A20
    int 0x15
    call check_a20
    jnz .verify

    in al, 0x92                  ; fast A20 via System Control Port A
    or al, 2                     ; bit 1 = A20 enable
    and al, 0xFE                 ; bit 0 = fast reset - keep it clear!
    out 0x92, al

.verify:
    call check_a20
    jz .off
    mov byte [a20_enabled], 1
    ret
.off:
    mov byte [a20_enabled], 0
    ret

; ZF=0 if A20 enabled, ZF=1 if disabled (0x100500 aliases 0x000500)
check_a20:
    pushf
    push ds
    push es
    push di
    push si
    cli
    xor ax, ax
    mov es, ax
    mov di, 0x0500              ; ES:DI = 0000:0500  -> linear 0x00500
    mov ax, 0xFFFF
    mov ds, ax
    mov si, 0x0510              ; DS:SI = FFFF:0510  -> linear 0x100500

    mov al, [es:di]            ; save originals in AL/AH
    mov ah, [ds:si]
    push ax

    mov byte [es:di], 0x00     ; write two distinct values
    mov byte [ds:si], 0xFF
    cmp byte [es:di], 0xFF     ; aliased? then [es:di] now reads 0xFF

    pop ax                     ; restore originals
    mov [ds:si], ah
    mov [es:di], al

    mov ax, 0                  ; equal (aliased) -> disabled
    je .done
    mov ax, 1                  ; independent -> enabled
.done:
    pop si
    pop di
    pop es
    pop ds
    popf
    or ax, ax                  ; ZF reflects enabled(1)/disabled(0)
    ret

a20_enabled: db 0
