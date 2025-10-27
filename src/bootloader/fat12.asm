; filepath: /home/nazr/Desktop/projects/x86_boot/src/bootloader/fat12.asm
; FAT12 filesystem driver

    ; Read FAT table
    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00
    call disk_read

    ; Calculate root directory location
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx
    add ax, [bdb_reserved_sectors]
    push ax

    ; Calculate root directory size
    mov ax, [bdb_dir_entires_count]
    shl ax, 5
    xor dx, dx
    div word [bdb_bytes_per_sector]
    test dx, dx
    jz .root_dir_size_ok
    inc ax
    
.root_dir_size_ok:
    mov cl, al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    ; Search for kernel
    xor bx, bx
    mov di, buffer

.search_kernel:
    mov si, kernel_name
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found_kernel

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entires_count]
    jl .search_kernel

    mov si, kernel_not_found_msg
    call print
    jmp halt

.found_kernel:
    mov si, kernel_found_msg
    call print
    
    mov ax, [di + 26]
    mov [kernel_cluster], ax

    ; Load FAT
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; Load kernel
    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset

.load_kernel_loop:
    mov ax, [kernel_cluster]
    add ax, 31  ; Convert cluster to LBA
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read
    
    add bx, [bdb_bytes_per_sector]

    ; Get next cluster
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even
    
.odd:
    shr ax, 4
    jmp .next_cluster
    
.even:
    and ax, 0x0FFF

.next_cluster:
    cmp ax, 0x0FF8
    jae .kernel_loaded

    mov [kernel_cluster], ax
    jmp .load_kernel_loop

.kernel_loaded:
    mov si, kernel_loaded_msg
    call print
    
    mov dl, [ebr_drive_number]
    
    ; Setup segments for kernel
    mov ax, kernel_load_segment
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF

    jmp kernel_load_segment:kernel_load_offset

