bits 16
org 0x7E00

KERNEL_SEG equ 0x1000
CFG_SEG    equ 0x0400                    ; config buffer (linear 0x4000)

%ifndef BOOT_PART
%define BOOT_PART 0                      ; which MBR partition to boot (0-3)
%endif

stage2_start:
    mov [drive], dl
    xor ax, ax
    mov ds, ax
    mov es, ax
    cld

    call fat_detect
    call menu_main                       ; menu: user picks a kernel (loads it to KERNEL_SEG:0)
    call splash                          ; THEN the graphical splash (mode 13h, real mode)
    call enable_a20                      ; unlock memory above 1 MB (protected-mode prep)
    call get_e820                        ; grab the memory map (last BIOS call)
    call gdt_install                     ; point the CPU at our GDT
    jmp switch_to_pm

; detect filesystem: set [fat_is32], [partition_start], [bpb_ptr]
fat_detect:
    mov al, [0x7C00 + 0x1BE + (BOOT_PART*16) + 4]   ; selected partition's type
    test al, al
    jz .novbr
    mov eax, [0x7C00 + 0x1BE + (BOOT_PART*16) + 8]  ; its start LBA
    mov [partition_start], eax
    xor bx, bx
    mov es, bx
    mov bx, VBR_BUF
    mov cx, 1
    call read_sectors32                  ; load the partition's VBR (its BPB)
    mov word [bpb_ptr], VBR_BUF
    jmp .decide
.novbr:
    xor eax, eax
    mov [partition_start], eax
    mov word [bpb_ptr], 0x7C00
.decide:
    mov bx, [bpb_ptr]
    mov ax, [bx+0x16]                    ; sectors_per_fat_16 == 0 -> FAT32
    test ax, ax
    jz .fat32
    mov byte [fat_is32], 0
    ret
.fat32:
    mov byte [fat_is32], 1
    ret

; load file [find_name] to [dest_seg]:0 via the detected driver; CF if not found
fat_load_file:
    cmp byte [fat_is32], 0
    jne .f32
    jmp fat12_load_file
.f32:
    jmp fat32_load_file

; read CX sectors from LBA AX into ES:BX (16-bit LBA, used by fat12)
read_sectors:
    mov [dap_count], cx
    mov [dap_off], bx
    mov [dap_seg], es
    mov [dap_lba], ax
    mov word [dap_lba+2], 0
    mov ah, 0x42
    mov dl, [drive]
    mov si, dap
    int 0x13
    jc .fail
    ret
.fail:
    mov si, msg_diskerr
    call print_string
    jmp halt

print_string:
    push ax
    push bx
    push si
    mov bh, 0
.next:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    pop si
    pop bx
    pop ax
    ret

halt:
    cli
    hlt
    jmp halt

drive: db 0

dap:
    db 0x10
    db 0
dap_count: dw 0
dap_off:   dw 0
dap_seg:   dw 0
dap_lba:   dd 0
           dd 0

fat_is32:  db 0
find_name: dw 0
dest_seg:  dw 0
file_size: dd 0

msg_diskerr: db 'Disk read error', 0x0D, 0x0A, 0

%include "fat12.asm"
%include "fat32.asm"
%include "menu.asm"
%include "gdt.asm"
%include "a20.asm"
%include "e820.asm"
%include "splash.asm"

; ---- the real -> protected mode switch --------------------------------------
switch_to_pm:
    cli                                  ; real-mode IVT is about to be invalid
    mov eax, cr0
    or  al, 1                            ; set PE (Protection Enable)
    mov cr0, eax
    jmp CODE_SEG:pm_entry                ; far jump: reload CS=0x08, flush pipeline

[bits 32]
pm_entry:
    mov ax, DATA_SEG                     ; reload data selectors (flat data segment)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000                     ; 32-bit stack

    mov esi, KERNEL_SEG*16               ; scan the loaded kernel for the Multiboot header
    mov ecx, [file_size]
    shr ecx, 2                           ; dwords
    cmp ecx, 2048                        ; ...within the first 8 KB
    jbe .have_len
    mov ecx, 2048
.have_len:
.scan:
    cmp dword [esi], 0x1BADB002
    je .multiboot
    add esi, 4
    dec ecx
    jnz .scan
    jmp KERNEL_SEG*16                    ; no header -> plain binary kernel (our C kernel)

.multiboot:
    call build_mb_info
    mov eax, 0x2BADB002                  ; the handoff magic
    mov ebx, mb_info                     ; -> the info structure
    jmp KERNEL_SEG*16

; turn the E820 map into a Multiboot info struct + mmap
build_mb_info:
    mov esi, e820_map
    mov edi, mb_mmap
    movzx ecx, word [e820_count]
.mm:
    mov dword [edi], 20                  ; size (entry bytes excluding this field)
    mov eax, [esi];    mov [edi+4],  eax ; base low
    mov eax, [esi+4];  mov [edi+8],  eax ; base high
    mov eax, [esi+8];  mov [edi+12], eax ; length low
    mov eax, [esi+12]; mov [edi+16], eax ; length high
    mov eax, [esi+16]; mov [edi+20], eax ; type
    add esi, 24
    add edi, 24
    dec ecx
    jnz .mm

    movzx eax, word [e820_count]
    imul eax, eax, 24
    mov [mb_info+44], eax                ; mmap_length
    mov dword [mb_info+48], mb_mmap      ; mmap_addr
    mov dword [mb_info], 0x41            ; flags: mem (bit0) + mmap (bit6)
    mov dword [mb_info+4], 640           ; mem_lower (KB)

    mov dword [mb_info+8], 0             ; mem_upper = usable RAM at 1 MB, in KB
    mov esi, e820_map
    movzx ecx, word [e820_count]
.mu:
    cmp dword [esi], 0x00100000
    jne .mu_next
    cmp dword [esi+4], 0
    jne .mu_next
    cmp dword [esi+16], 1
    jne .mu_next
    mov eax, [esi+8]
    shr eax, 10
    mov [mb_info+8], eax
    jmp .mu_done
.mu_next:
    add esi, 24
    dec ecx
    jnz .mu
.mu_done:
    ret

align 4
mb_info: times 90 db 0
mb_mmap: times MAX_E820*24 db 0
