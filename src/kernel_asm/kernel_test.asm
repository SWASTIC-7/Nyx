bits 32
org 0x10000                        ; loaded here; entered by stage2 after the PM switch

%ifdef KB
%define KID 'B'
%else
%define KID 'A'
%endif

start:
    mov esi, msg1
    mov edi, 0xB8000 + 160*2       ; row 2
    call puts
    mov esi, msg2
    mov edi, 0xB8000 + 160*3       ; row 3
    call puts
.hang:
    hlt
    jmp .hang

; ESI = NUL-terminated string, EDI = VGA cell pointer
puts:
    mov ah, 0x0A                    ; light green
.l:
    lodsb
    test al, al
    jz .d
    mov [edi], al
    mov [edi+1], ah
    add edi, 2
    jmp .l
.d:
    ret

msg1: db 'Kernel ', KID, ' running in 32-bit protected mode', 0
msg2: db 'Loaded by Nyx via FAT, entered after the CR0.PE switch', 0
times 1024-($-$$) db 0             ; 2 clusters
