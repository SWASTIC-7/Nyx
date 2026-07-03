bits 32
org 0x10000                        ; loaded + entered here

start:
    jmp real_start

align 4                            ; the Multiboot header (found by the bootloader's scan)
mb_header:
    dd 0x1BADB002                  ; magic
    dd 0x00000000                  ; flags
    dd -(0x1BADB002 + 0)           ; checksum

real_start:
    mov ebp, ebx                   ; save the Multiboot info pointer
    cmp eax, 0x2BADB002            ; were we booted by a Multiboot loader?
    jne .bad

    mov edi, 0xB8000               ; clear screen
    mov ecx, 80*25
    mov ax, 0x0720
    rep stosw

    mov edi, 0xB8000               ; "Successfully booted to <name>, hi <name> user"
    mov esi, msg_pre
    call puts
    mov esi, kname
    call puts
    mov esi, msg_mid
    call puts
    mov esi, kname
    call puts
    mov esi, msg_end
    call puts
    jmp .hang
.bad:
    mov esi, msg_bad
    mov edi, 0xB8000
    call puts
.hang:
    hlt
    jmp .hang

puts:                              ; ESI = string, EDI = VGA ptr
    push eax
    mov ah, 0x0A
.l:
    lodsb
    test al, al
    jz .d
    mov [edi], al
    mov [edi+1], ah
    add edi, 2
    jmp .l
.d:
    pop eax
    ret

%ifdef NYX2
kname:   db 'NyxOS2', 0
%else
kname:   db 'NyxOS', 0
%endif
msg_pre: db 'Successfully booted to ', 0
msg_mid: db ', hi ', 0
msg_end: db ' user', 0
msg_bad: db 'ERROR: not booted as Multiboot', 0
