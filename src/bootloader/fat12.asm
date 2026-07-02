; FAT12 driver - reads BPB from the resident boot sector at 0x7C00,
; finds KERNEL.BIN in the root directory, follows its cluster chain
; and loads it to KERNEL_SEG:0000.

BPB          equ 0x7C00
bpb_bps      equ BPB+0x0B               ; bytes per sector
bpb_spc      equ BPB+0x0D               ; sectors per cluster
bpb_reserved equ BPB+0x0E
bpb_numfats  equ BPB+0x10
bpb_rootent  equ BPB+0x11
bpb_spf      equ BPB+0x16               ; sectors per FAT

FAT_BUF equ 0x0500                       ; FAT #1 loaded here
DIR_BUF equ 0x2000                       ; root directory loaded here

; load the file named at [find_name] to [dest_seg]:0; CF set if not found
fat12_load_file:
    mov ax, [bpb_reserved]
    mov [fat_start], ax

    mov al, [bpb_numfats]
    xor ah, ah
    mov cx, [bpb_spf]
    mul cx                               ; numfats * sectors_per_fat
    add ax, [fat_start]
    mov [root_start], ax

    mov ax, [bpb_rootent]
    mov cx, 32
    mul cx                               ; root_entries * 32 bytes
    add ax, [bpb_bps]
    dec ax
    xor dx, dx
    div word [bpb_bps]                   ; ceil(dir bytes / bytes_per_sector)
    mov [root_sectors], ax

    add ax, [root_start]
    mov [data_start], ax

    xor ax, ax
    mov es, ax
    mov ax, [fat_start]
    mov cx, [bpb_spf]
    mov bx, FAT_BUF
    call read_sectors

    mov ax, [root_start]
    mov cx, [root_sectors]
    mov bx, DIR_BUF
    call read_sectors

    mov di, DIR_BUF
    mov dx, [bpb_rootent]
.scan:
    cmp byte [di], 0x00                  ; 0x00 = end of directory
    je .notfound
    cmp byte [di], 0xE5                  ; 0xE5 = deleted entry
    je .next
    mov si, [find_name]
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found
.next:
    add di, 32
    dec dx
    jnz .scan
.notfound:
    stc                                  ; caller decides what to do
    ret
.found:
    mov cx, [di+28]                      ; remember the file size (dword)
    mov [file_size], cx
    mov cx, [di+30]
    mov [file_size+2], cx
    mov word [load_off], 0
    mov ax, [di+26]                      ; first cluster (low word)

.load:
    push ax
    sub ax, 2
    xor cx, cx
    mov cl, [bpb_spc]
    mul cx                               ; (cluster-2) * sectors_per_cluster
    add ax, [data_start]
    mov bx, [dest_seg]
    mov es, bx
    mov bx, [load_off]
    xor cx, cx
    mov cl, [bpb_spc]
    call read_sectors
    shl cx, 9                            ; cluster size in bytes
    add [load_off], cx
    pop ax
    call fat12_next
    cmp ax, 0x0FF8                        ; >= 0xFF8 = end of chain
    jae .done
    jmp .load
.done:
    clc
    ret

; next cluster in chain: AX = current cluster -> AX = next (12-bit)
fat12_next:
    push bx
    push cx
    push dx
    mov bx, ax
    mov cx, ax
    shr cx, 1
    add bx, cx                           ; offset = cluster + cluster/2
    mov dx, [FAT_BUF + bx]
    test ax, 1
    jz .even
    shr dx, 4                            ; odd cluster -> high 12 bits
    jmp .store
.even:
    and dx, 0x0FFF                       ; even cluster -> low 12 bits
.store:
    mov ax, dx
    pop dx
    pop cx
    pop bx
    ret

kernel_name:  db 'KERNEL  BIN'
fat_start:    dw 0
root_start:   dw 0
root_sectors: dw 0
data_start:   dw 0
load_off:     dw 0
msg_nokernel: db 'KERNEL.BIN not found', 0x0D, 0x0A, 0
