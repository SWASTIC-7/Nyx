; FAT32 driver. BPB lives in the partition VBR (located by fat_detect), all
; sectors are absolute LBAs (partition_start already folded in). The FAT is too
; big to cache, so entries are read one sector at a time on demand.

VBR_BUF equ 0x0600               ; partition VBR / BPB
FAT_SEC equ 0x0A00               ; one FAT sector, on demand
F32_DIR equ 0x1000               ; one directory cluster

; read CX sectors from 32-bit LBA EAX into ES:BX
read_sectors32:
    mov [dap_count], cx
    mov [dap_off], bx
    mov [dap_seg], es
    mov [dap_lba], eax
    mov dword [dap_lba+4], 0
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

; EAX = cluster -> EAX = absolute LBA of its first sector
cluster_to_lba:
    sub eax, 2
    movzx ecx, byte [f32_spc]
    mul ecx
    add eax, [f32_data_start]
    ret

; EAX = cluster -> EAX = next cluster (28-bit, masked)
fat32_next:
    push ebx
    push ecx
    push edx
    push es
    mov edx, eax
    shl edx, 2                   ; byte offset of entry in the FAT
    mov eax, edx
    shr eax, 9                   ; / 512 = sector index
    add eax, [f32_fat_start]
    and edx, 0x1FF               ; offset within that sector
    push dx                      ; read_sectors32 clobbers DX (dl=drive)
    xor bx, bx
    mov es, bx
    mov bx, FAT_SEC
    mov cx, 1
    call read_sectors32
    pop bx                       ; recover the entry offset
    mov eax, [FAT_SEC + bx]
    and eax, 0x0FFFFFFF
    pop es
    pop edx
    pop ecx
    pop ebx
    ret

; load the file named at [find_name] to [dest_seg]:0; CF set if not found
fat32_load_file:
    mov bx, [bpb_ptr]
    mov ax, [bx+0x0E]
    mov [f32_reserved], ax
    mov al, [bx+0x10]
    mov [f32_numfats], al
    mov al, [bx+0x0D]
    mov [f32_spc], al
    mov eax, [bx+0x24]
    mov [f32_spf], eax
    mov eax, [bx+0x2C]
    mov [f32_rootclus], eax

    movzx eax, word [f32_reserved]        ; fat_start = part_start + reserved
    add eax, [partition_start]
    mov [f32_fat_start], eax

    movzx eax, byte [f32_numfats]         ; data_start = + num_fats*spf32
    mov ecx, [f32_spf]
    mul ecx
    movzx ebx, word [f32_reserved]
    add eax, ebx
    add eax, [partition_start]
    mov [f32_data_start], eax

    mov eax, [f32_rootclus]               ; scan root dir (a cluster chain)
    mov [f32_dirclus], eax
.dir_cluster:
    mov eax, [f32_dirclus]
    call cluster_to_lba
    xor bx, bx
    mov es, bx
    mov bx, F32_DIR
    movzx cx, byte [f32_spc]
    call read_sectors32

    mov di, F32_DIR
    movzx cx, byte [f32_spc]              ; entries in this cluster = spc*512/32
    shl cx, 9
    shr cx, 5
.scan:
    cmp byte [di], 0x00
    je .notfound
    cmp byte [di], 0xE5
    je .skip
    push cx
    push di
    mov si, [find_name]
    mov cx, 11
    repe cmpsb
    pop di
    pop cx
    je .found
.skip:
    add di, 32
    dec cx
    jnz .scan
    mov eax, [f32_dirclus]               ; next directory cluster
    call fat32_next
    mov [f32_dirclus], eax
    cmp eax, 0x0FFFFFF8
    jae .notfound
    jmp .dir_cluster

.notfound:
    stc
    ret

.found:
    mov eax, [di+0x1C]                   ; file size
    mov [file_size], eax
    movzx eax, word [di+0x14]            ; first cluster = high<<16 | low
    shl eax, 16
    mov ax, [di+0x1A]
    mov [f32_cluster], eax
    mov word [f32_load_off], 0

.load:
    mov eax, [f32_cluster]
    call cluster_to_lba
    mov bx, [dest_seg]
    mov es, bx
    mov bx, [f32_load_off]
    movzx cx, byte [f32_spc]
    call read_sectors32
    movzx ax, byte [f32_spc]
    shl ax, 9
    add [f32_load_off], ax
    mov eax, [f32_cluster]
    call fat32_next
    mov [f32_cluster], eax
    cmp eax, 0x0FFFFFF8
    jae .done
    jmp .load
.done:
    clc
    ret

partition_start: dd 0
bpb_ptr:         dw 0
f32_reserved:    dw 0
f32_numfats:     db 0
f32_spc:         db 0
f32_spf:         dd 0
f32_rootclus:    dd 0
f32_fat_start:   dd 0
f32_data_start:  dd 0
f32_dirclus:     dd 0
f32_cluster:     dd 0
f32_load_off:    dw 0
msg_nokernel32:  db 'KERNEL.BIN not found (fat32)', 0x0D, 0x0A, 0
