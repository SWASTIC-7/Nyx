; Boot menu (real mode). Reads NYX.CFG from the FAT volume, parses timeout/
; default/entries, draws a text-mode menu, and lets the user pick with the
; arrow keys (int 0x16) or auto-boots the default after a countdown.
; Config format (one field per line):
;   <timeout seconds>
;   <default index>
;   <Label> <FILENAME.EXT>
;   ...

CFG_BUF     equ 0x4000               ; linear address the config text loads to
MAX_ENTRIES equ 8

; try NYX.CFG -> menu -> load choice; if no config, fall back to KERNEL.BIN
menu_main:
    mov word [find_name], cfg_name
    mov word [dest_seg], CFG_SEG
    call fat_load_file
    jc .fallback
    call parse_config
    cmp byte [num_entries], 0
    je .fallback
    call run_menu                     ; sets [find_name] = chosen 8.3 name
    mov word [dest_seg], KERNEL_SEG
    call fat_load_file
    jc .err
    ret
.fallback:
    mov word [find_name], kernel_name
    mov word [dest_seg], KERNEL_SEG
    call fat_load_file
    jc .err
    ret
.err:
    mov si, msg_loaderr
    call print_string
    jmp halt

; ---- config parsing --------------------------------------------------------
parse_config:
    xor ax, ax
    mov es, ax                        ; name_to_83's stosb writes to ES:DI
    mov bx, [file_size]
    mov byte [CFG_BUF+bx], 0          ; NUL-terminate the loaded text
    mov si, CFG_BUF
    call parse_uint
    mov [cfg_timeout], ax
    call parse_uint
    mov [cfg_default], ax
    mov byte [num_entries], 0
.entry:
    call skip_eol
    mov al, [si]
    or al, al
    jz .done
    movzx bx, byte [num_entries]      ; entry_label[n] = start of label
    shl bx, 1
    mov [entry_label+bx], si
.lbl:
    mov al, [si]
    cmp al, ' '                       ; space separates label from filename
    je .lblend
    call is_term                      ; NUL/CR/LF = malformed line
    je .done
    inc si
    jmp .lbl
.lblend:
    mov byte [si], 0                  ; terminate the label
    inc si
.sp:
    cmp byte [si], ' '
    jne .conv
    inc si
    jmp .sp
.conv:
    movzx ax, byte [num_entries]      ; dest = entry_name + n*11
    mov bx, 11
    mul bx
    add ax, entry_name
    mov di, ax
    call name_to_83
.fn:
    mov al, [si]
    call is_term
    je .fnend
    inc si
    jmp .fn
.fnend:
    inc byte [num_entries]
    cmp byte [num_entries], MAX_ENTRIES
    jb .entry
.done:
    ret

parse_uint:                           ; SI -> AX = number, SI past this line
    xor ax, ax
.d:
    mov cl, [si]
    cmp cl, '0'
    jb .end
    cmp cl, '9'
    ja .end
    imul ax, ax, 10
    sub cl, '0'
    xor ch, ch
    add ax, cx
    inc si
    jmp .d
.end:
    call skip_eol
    ret

skip_eol:                             ; advance SI past CR/LF
    cmp byte [si], 0x0D
    je .a
    cmp byte [si], 0x0A
    je .a
    ret
.a:
    inc si
    jmp skip_eol

is_term:                              ; ZF=1 if AL is NUL/space/CR/LF
    cmp al, 0
    je .y
    cmp al, ' '
    je .y
    cmp al, 0x0D
    je .y
    cmp al, 0x0A
    je .y
    or al, al                         ; AL nonzero here -> ZF=0
    ret
.y:
    cmp al, al                        ; ZF=1
    ret

upcase:
    cmp al, 'a'
    jb .r
    cmp al, 'z'
    ja .r
    sub al, 0x20
.r:
    ret

name_to_83:                           ; SI=filename, DI=dest(11 bytes)
    push ax
    push cx
    push si
    push di
    mov bx, di
    mov al, ' '                       ; blank-fill 11
    mov cx, 11
    rep stosb
    mov di, bx
    mov cx, 8
.nm:
    mov al, [si]
    call is_term
    je .fin
    cmp al, '.'
    je .dot
    call upcase
    mov [di], al
    inc di
    inc si
    dec cx
    jnz .nm
.sk:
    mov al, [si]
    call is_term
    je .fin
    cmp al, '.'
    je .dot
    inc si
    jmp .sk
.dot:
    inc si
    mov di, bx
    add di, 8
    mov cx, 3
.ex:
    mov al, [si]
    call is_term
    je .fin
    call upcase
    mov [di], al
    inc di
    inc si
    dec cx
    jnz .ex
.fin:
    pop di
    pop si
    pop cx
    pop ax
    ret

; ---- menu UI ---------------------------------------------------------------
run_menu:
    mov ax, 0x0003
    int 0x10                          ; 80x25 colour text (clears screen)
    call draw_splash
    mov ax, [cfg_default]
    mov [sel], ax
    mov byte [timeout_active], 1
    call get_ticks
    mov [start_ticks], eax
    movzx eax, word [cfg_timeout]
    mov ecx, 18                        ; ~18.2 BIOS ticks/second
    mul ecx
    mov [timeout_ticks], eax
.loop:
    call draw_entries
    call draw_status
    mov ah, 0x01
    int 0x16                          ; key waiting?
    jz .nokey
    mov ah, 0
    int 0x16
    mov byte [timeout_active], 0       ; any key cancels auto-boot
    cmp al, 0x0D
    je .select
    cmp ah, 0x48                       ; up arrow
    je .up
    cmp ah, 0x50                       ; down arrow
    je .down
    jmp .loop
.up:
    cmp word [sel], 0
    je .loop
    dec word [sel]
    jmp .loop
.down:
    mov ax, [sel]
    inc ax
    movzx bx, byte [num_entries]
    cmp ax, bx
    jae .loop
    mov [sel], ax
    jmp .loop
.nokey:
    cmp byte [timeout_active], 0
    je .loop
    call get_ticks
    sub eax, [start_ticks]
    cmp eax, [timeout_ticks]
    jb .loop
    mov ax, [cfg_default]
    mov [sel], ax
.select:
    mov ax, [sel]
    mov bx, 11
    mul bx
    add ax, entry_name
    mov [find_name], ax
    ret

get_ticks:                            ; EAX = BIOS tick counter (BDA 0x046C)
    mov eax, [0x046C]
    ret

draw_splash:
    mov dh, 1
    mov dl, 29
    mov bl, 0x1F
    mov si, msg_title
    call print_at
    mov dh, 3
    mov dl, 27
    mov bl, 0x07
    mov si, msg_sub
    call print_at
    ret

draw_entries:
    xor cx, cx
.e:
    movzx ax, byte [num_entries]
    cmp cx, ax
    jae .done
    mov bl, 0x07
    mov ax, [sel]
    cmp ax, cx
    jne .a
    mov bl, 0x70                       ; highlight selected
.a:
    mov dh, cl
    add dh, 6
    mov dl, 28
    mov si, cx                        ; index via SI (mov bx,cx would clobber BL=attr)
    shl si, 1
    mov si, [entry_label+si]
    push cx
    call print_at
    pop cx
    inc cx
    jmp .e
.done:
    ret

draw_status:
    mov dh, 18                         ; clear the status row first
    mov dl, 15
    mov bl, 0x08
    mov si, msg_blank
    call print_at
    cmp byte [timeout_active], 0
    je .keys
    call get_ticks
    sub eax, [start_ticks]
    xor edx, edx
    mov ecx, 18
    div ecx                            ; eax = elapsed seconds
    mov bx, [cfg_timeout]
    sub bx, ax
    jns .pos                           ; clamp a negative remainder to 0
    xor bx, bx
.pos:
    mov ax, bx
    cmp ax, 99
    jbe .ok
    mov ax, 99
.ok:
    mov dh, 18
    mov dl, 15
    mov bl, 0x0E
    call print_num_at                  ; "NN"
    mov dh, 18
    mov dl, 18
    mov bl, 0x0E
    mov si, msg_timeout
    call print_at
    ret
.keys:
    mov dh, 18
    mov dl, 15
    mov bl, 0x08
    mov si, msg_keys
    call print_at
    ret

print_num_at:                          ; AX=num(0-99) at DH,DL attr BL
    mov cl, 10
    div cl                             ; al=tens, ah=units
    add al, '0'
    add ah, '0'
    mov [numbuf], al
    mov [numbuf+1], ah
    mov byte [numbuf+2], 0
    mov si, numbuf
    call print_at
    ret

; print NUL-terminated [SI] at row DH col DL with attribute BL
print_at:
    push ax
    push cx
    push dx
    push si
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    movzx ax, dh
    mov cl, 80
    mul cl                            ; ax = row*80 (8-bit mul keeps DX/dl intact)
    movzx cx, dl
    add ax, cx
    shl ax, 1
    mov di, ax
    mov ah, bl
.p:
    lodsb
    test al, al
    jz .d
    mov [es:di], al
    mov [es:di+1], ah
    add di, 2
    jmp .p
.d:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

cfg_name:       db 'NYX     CFG'
cfg_timeout:    dw 5
cfg_default:    dw 0
num_entries:    db 0
sel:            dw 0
start_ticks:    dd 0
timeout_ticks:  dd 0
timeout_active: db 1
numbuf:         db 0, 0, 0
entry_label:    times MAX_ENTRIES dw 0
entry_name:     times MAX_ENTRIES*11 db 0
msg_title:      db '== NYX BOOTLOADER ==', 0
msg_sub:        db 'Select a kernel to boot:', 0
msg_timeout:    db 'sec: booting default (press a key to choose)', 0
msg_keys:       db 'Up/Down to move, Enter to boot.', 0
msg_blank:      db '                                                    ', 0
msg_loaderr:    db 'load error', 0x0D, 0x0A, 0
