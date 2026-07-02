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
    call menu_main                       ; loads the chosen kernel to KERNEL_SEG:0
    call enable_a20                      ; unlock memory above 1 MB (protected-mode prep)
    call get_e820                        ; grab the memory map (last BIOS call)
    call gdt_install                     ; point the CPU at our GDT
    jmp KERNEL_SEG:0x0000

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
