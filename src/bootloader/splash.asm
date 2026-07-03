; VGA mode 13h boot splash - draws the SELECTED kernel's name (NyxOS / NyxOS2)
; as a large brushed-silver wordmark on black. Letters are hand-designed 24x32
; glyphs (glyphs.inc) drawn at native resolution -> crisp, no scaling artifacts.
; Real mode; shown after the menu selection, before the protected-mode switch.

VGA_SEG  equ 0xA000
LOGO_Y   equ 84                    ; top scanline of the wordmark
GLYPH_H  equ 32
GLYPH_SZ equ GLYPH_H*3             ; 96 bytes per glyph (3 bytes/row)
ADVANCE  equ 26                    ; glyph pitch (24 wide + 2 gap)

splash:
    mov ax, 0x0013                 ; mode 13h (320x200x256)
    int 0x10
    call splash_palette
    call splash_clear
    call splash_logo
    call splash_line
    call splash_hold
    mov ax, 0x0003                 ; restore text mode
    int 0x10
    ret

splash_palette:
    mov al, 0                      ; index 0 = black
    mov dx, 0x3C8
    out dx, al
    mov dx, 0x3C9
    xor al, al
    out dx, al
    out dx, al
    out dx, al
    mov al, 128                    ; 128..135 = metallic silver gradient
    mov dx, 0x3C8
    out dx, al
    mov dx, 0x3C9
    mov si, metal_pal
    mov cx, 24
.mp:
    lodsb
    out dx, al
    loop .mp
    ret

splash_clear:
    mov ax, VGA_SEG
    mov es, ax
    xor di, di
    xor al, al
    mov cx, 64000
    rep stosb
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
    mov bx, 320                    ; centre it
    sub bx, ax
    shr bx, 1
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

; AL = char; draw its 24x32 glyph at [cur_x],LOGO_Y in silver (unknown -> blank)
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
    add si, ax                     ; si -> glyph's 32 rows
    mov ax, LOGO_Y
    mov dx, 320
    mul dx
    add ax, [cur_x]
    mov di, ax                     ; di -> first scanline
    xor bp, bp                     ; row 0..31
.row:
    mov dl, 128                    ; one flat metallic silver (no gradient)
    push di
    mov ah, [si]                   ; 3 bytes -> 24 px, MSB = leftmost
    call emit8
    mov ah, [si+1]
    call emit8
    mov ah, [si+2]
    call emit8
    add si, 3
    pop di
    add di, 320
    inc bp
    cmp bp, GLYPH_H
    jb .row
.skip:
    pop si
    ret

emit8:                              ; draw 8 px from AH (MSB first), shade DL
    push cx
    mov cx, 8
.b:
    shl ah, 1
    jnc .n
    mov [es:di], dl
.n:
    inc di
    loop .b
    pop cx
    ret

splash_line:                        ; silver underline spanning the word
    mov ax, VGA_SEG
    mov es, ax
    mov bp, 122
.ly:
    mov ax, bp
    mov bx, 320
    mul bx
    add ax, [word_x0]
    mov di, ax
    mov al, 131
    mov cx, [word_w]
    rep stosb
    inc bp
    cmp bp, 124
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

metal_pal:                         ; RGB (6-bit) for silver shades 128..135
    db 56,56,62
    db 62,62,63
    db 52,52,58
    db 42,42,50
    db 48,48,54
    db 36,36,44
    db 30,30,40
    db 24,24,34
word_x0: dw 0
word_w:  dw 0
cur_x:   dw 0
%include "glyphs.inc"
