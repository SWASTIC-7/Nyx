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

    mov esi, msg_ok
    mov edi, 0xB8000
    call puts

    mov eax, [ebp+8]               ; mem_upper: usable KB above 1 MB (our E820 mmap)
    mov edi, 0xB8000 + 160         ; row 1
    call putnum
    mov esi, msg_kb
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

putnum:                            ; EAX = number, EDI = VGA ptr
    push ebx
    push ecx
    push edx
    mov ebx, 10
    xor ecx, ecx
.div:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz .div
.emit:
    pop eax
    add al, '0'
    mov [edi], al
    mov byte [edi+1], 0x0A
    add edi, 2
    dec ecx
    jnz .emit
    pop edx
    pop ecx
    pop ebx
    ret

msg_ok:  db 'Multiboot handoff OK  (EAX=0x2BADB002, EBX -> info struct)', 0
msg_kb:  db ' KB usable above 1MB  (from E820 via the Multiboot mmap)', 0
msg_bad: db 'ERROR: not booted as Multiboot', 0
