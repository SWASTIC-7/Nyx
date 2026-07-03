; VGA mode 12h boot splash (640x480, 16 colours - 4x the pixels of mode 13h, so
; the wordmark is much sharper). Draws the SELECTED kernel name (NyxOS / NyxOS2)
; as a large 48x64 wordmark in flat metallic silver on black. Mode 12h is planar,
; so we write whole 8-pixel bytes via the VGA set/reset hardware (fast, no BIOS
; per-pixel calls). Real mode; shown after the menu selection, before the switch.

VGA_SEG   equ 0xA000
SILVER    equ 7                    ; light-grey attribute, tinted to silver below
GLYPH_W   equ 48
GLYPH_H   equ 64
GBYTES    equ GLYPH_W/8            ; 6 bytes per glyph row
GLYPH_SZ  equ GBYTES*GLYPH_H       ; 384 bytes per glyph
ADVANCE   equ 56                   ; glyph pitch (byte-aligned: 7 bytes)
SCR_BYTES equ 80                   ; bytes per 640-pixel scanline
LOGO_Y    equ 208                  ; (480-64)/2

splash:
    mov ax, 0x0012                 ; mode 12h -> 640x480x16, screen cleared to black
    int 0x10
    mov ax, 0x1010                 ; tint attribute 7 to a cool metallic silver
    mov bx, SILVER
    mov dh, 46
    mov ch, 46
    mov cl, 52
    int 0x10
    call splash_setgc
    call splash_logo
    call splash_line
    call splash_resetgc
    call splash_hold
    mov ax, 0x0003                 ; restore text mode
    int 0x10
    ret

; program the Graphics Controller: every CPU write paints silver on the bits set
; in the Bit Mask register, leaving the rest untouched (read latches the old data)
splash_setgc:
    mov dx, 0x3CE
    mov ax, (SILVER<<8) | 0x00     ; GC0 Set/Reset = silver colour
    out dx, ax
    mov ax, 0x0F01                 ; GC1 Enable Set/Reset = all 4 planes
    out dx, ax
    ret

splash_resetgc:
    mov dx, 0x3CE
    mov ax, 0xFF08                 ; GC8 Bit Mask = 0xFF (restore default)
    out dx, ax
    mov ax, 0x0001                 ; GC1 Enable Set/Reset = 0
    out dx, ax
    ret

splash_logo:
    mov ax, VGA_SEG
    mov es, ax
    mov si, [sel_label]            ; count characters in the chosen name
    xor cx, cx
.cnt:
    cmp byte [si], 0
    je .cdone
    inc si
    inc cx
    jmp .cnt
.cdone:
    mov ax, ADVANCE                ; word width = count * pitch
    mul cx
    mov [word_w], ax
    mov bx, 640                    ; centre, then byte-align the start x
    sub bx, ax
    shr bx, 1
    and bx, 0xFFF8
    mov [word_x0], bx
    mov [cur_x], bx
    mov si, [sel_label]
.dc:
    mov al, [si]
    test al, al
    jz .done
    push si
    call draw_glyph
    add word [cur_x], ADVANCE
    pop si
    inc si
    jmp .dc
.done:
    ret

; AL = char; draw its 48x64 glyph at [cur_x](byte-aligned),LOGO_Y (unknown -> blank)
draw_glyph:
    push si
    mov si, glyph_chars
    xor bx, bx
.find:
    cmp bx, 6
    jae .skip
    cmp al, [si]
    je .got
    inc si
    inc bx
    jmp .find
.got:
    mov ax, GLYPH_SZ
    mul bx
    mov si, glyph_data
    add si, ax                     ; si -> glyph's rows (GBYTES bytes each)
    mov ax, LOGO_Y                 ; di = top-left screen byte
    mov bx, SCR_BYTES
    mul bx
    mov bx, [cur_x]
    shr bx, 3                      ; pixel x -> byte column
    add ax, bx
    mov di, ax
    mov bp, GLYPH_H
.row:
    push di
    xor cx, cx                     ; byte 0..GBYTES-1
.byte:
    mov ah, [si]                   ; glyph byte = which pixels to paint
    inc si
    mov al, 8                      ; GC8 Bit Mask = glyph byte
    mov dx, 0x3CE
    out dx, ax
    mov bx, cx
    mov dl, [es:di+bx]             ; read -> load latches (dummy)
    mov byte [es:di+bx], 0xFF      ; write -> silver where the mask bit is 1
    inc cx
    cmp cx, GBYTES
    jb .byte
    pop di
    add di, SCR_BYTES              ; next scanline
    dec bp
    jnz .row
.skip:
    pop si
    ret

splash_line:                        ; silver underline spanning the word
    mov ax, VGA_SEG
    mov es, ax
    mov dx, 0x3CE
    mov ax, 0xFF08                 ; full-byte writes
    out dx, ax
    mov bp, 288
.ly:
    mov ax, bp
    mov bx, SCR_BYTES
    mul bx
    mov bx, [word_x0]
    shr bx, 3
    add ax, bx
    mov di, ax
    mov cx, [word_w]
    shr cx, 3
.lx:
    mov bl, [es:di]                ; latch
    mov byte [es:di], 0xFF
    inc di
    dec cx
    jnz .lx
    inc bp
    cmp bp, 291
    jb .ly
    ret

splash_hold:
    mov eax, [0x046C]             ; BIOS tick counter
    mov ebx, eax
.w:
    mov eax, [0x046C]
    sub eax, ebx
    cmp eax, 40                   ; minimum ~2.2 s on screen
    jb .w
    ret

word_x0: dw 0
word_w:  dw 0
cur_x:   dw 0
%include "glyphs.inc"
