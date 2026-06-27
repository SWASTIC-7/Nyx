; filepath: /home/nazr/Desktop/projects/x86_boot/src/bootloader/fat32.asm
; FAT32 filesystem driver

    ; Get FAT32 specific values
    mov eax, [fat32_sectors_per_fat]
    mov [fat32_spf_value], eax
    mov eax, [fat32_root_cluster]
    mov [current_cluster], eax

    ; Load FAT table
    mov eax, [bdb_reserved_sectors]
    mov [fat_start_lba], eax
    
    ; Calculate data region start
    mov eax, [bdb_reserved_sectors]
    movzx ebx, byte [bdb_fat_count]
    mov ecx, [fat32_spf_value]
    imul ecx, ebx
    add eax, ecx
    mov [data_start_lba], eax

    ; Load root directory
    mov eax, [current_cluster]
    call fat32_cluster_to_lba
    
    mov cl, [bdb_sectors_per_cluster]
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    ; Search for kernel
    xor bx, bx
    mov di, buffer

.search_kernel:
    ; Check if end of directory
    cmp byte [di], 0
    je .kernel_not_found
    
    ; Check if deleted entry
    cmp byte [di], 0xE5
    je .next_entry

    ; Compare filename
    mov si, kernel_name
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found_kernel

.next_entry:
    add di, 32
    inc bx
    cmp bx, 16  ; 512 bytes / 32 bytes per entry
    jl .search_kernel

    ; Need to load next cluster of directory
    mov eax, [current_cluster]
    call fat32_get_next_cluster
    cmp eax, 0x0FFFFFF8
    jae .kernel_not_found
    
    mov [current_cluster], eax
    call fat32_cluster_to_lba
    mov cl, [bdb_sectors_per_cluster]
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read
    
    xor bx, bx
    mov di, buffer
    jmp .search_kernel

.kernel_not_found:
    mov si, kernel_not_found_msg
    call print
    jmp halt

.found_kernel:
    mov si, kernel_found_msg
    call print
    
    ; Get first cluster (high and low words)
    mov ax, [di + 20]
    shl eax, 16
    mov ax, [di + 26]
    mov [kernel_cluster], eax

    ; Load kernel
    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset

.load_kernel_loop:
    mov eax, [kernel_cluster]
    call fat32_cluster_to_lba
    
    mov cl, [bdb_sectors_per_cluster]
    mov dl, [ebr_drive_number]
    call disk_read
    
    movzx ax, byte [bdb_sectors_per_cluster]
    mul word [bdb_bytes_per_sector]
    add bx, ax

    ; Get next cluster
    mov eax, [kernel_cluster]
    call fat32_get_next_cluster
    
    cmp eax, 0x0FFFFFF8
    jae .kernel_loaded

    mov [kernel_cluster], eax
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

; Convert cluster number to LBA
; Input: EAX = cluster number
; Output: EAX = LBA
fat32_cluster_to_lba:
    sub eax, 2
    movzx ecx, byte [bdb_sectors_per_cluster]
    mul ecx
    add eax, [data_start_lba]
    ret

; Get next cluster from FAT
; Input: EAX = current cluster
; Output: EAX = next cluster
fat32_get_next_cluster:
    push ebx
    push ecx
    push edx
    
    ; Calculate FAT offset
    mov ebx, eax
    shl ebx, 2  ; cluster * 4
    
    ; Calculate FAT sector
    xor edx, edx
    movzx ecx, word [bdb_bytes_per_sector]
    div ecx
    
    add eax, [fat_start_lba]
    
    ; Read FAT sector
    push bx
    mov cl, 1
    mov dl, [ebr_drive_number]
    mov bx, buffer + 512
    call disk_read
    pop bx
    
    ; Get FAT entry
    and bx, 0x1FF
    mov eax, [buffer + 512 + bx]
    and eax, 0x0FFFFFFF
    
    pop edx
    pop ecx
    pop ebx
    ret

fat32_spf_value: dd 0
current_cluster: dd 0
fat_start_lba: dd 0
data_start_lba: dd 0

