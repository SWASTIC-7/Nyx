; E820 - ask BIOS for the physical memory map (int 0x15, EAX=0xE820).
; Last BIOS call before protected mode. Stored as a uniform array of 24-byte
; entries + a count, for the kernel / Multiboot info to read later.

MAX_E820 equ 24

get_e820:
    push es
    xor ax, ax
    mov es, ax                   ; entries live in segment 0
    mov word [e820_count], 0
    mov di, e820_map             ; ES:DI = first slot
    xor ebx, ebx                 ; continuation = 0 (first call)
.loop:
    mov eax, 0xE820
    mov edx, 0x534D4150          ; 'SMAP' - must be re-set every call
    mov ecx, 24                  ; entry buffer size
    int 0x15
    jc .done                     ; CF = error, or list finished
    cmp eax, 0x534D4150          ; BIOS must echo 'SMAP'
    jne .done
    inc word [e820_count]
    add di, 24                   ; next slot (uniform stride)
    test ebx, ebx                ; continuation 0 = that was the last entry
    jz .done
    cmp word [e820_count], MAX_E820
    jb .loop
.done:
    pop es
    ret

e820_count: dw 0
e820_map:   times MAX_E820*24 db 0
