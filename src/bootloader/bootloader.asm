org 0x7C00
bits 16


jmp short main
nop

bdb_oem: db  'MSWIN4.1'
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entires_count: dw 0E0h
bdb_total_sectors: dw 2880
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_total_sector_count: dd 0

ebr_drive_number:   db 0
ebr_reserved_number:   db 0
ebr_signature: db 0x29
ebr_volume_id:  db 12h,34h,56h,78h
ebr_volume_label:  db  'SWASTIC    '
ebr_system_id: db 'FAT12   '


main:

    mov ax,0
    mov ds,ax
    mov es,ax
    mov ss,ax

    mov sp,0x7C00

    ; mov [ebr_drive_number], dl
    ; mov ax,1
    ; mov cl,1
    ; mov bx, 0x7E00
    ; call disk_reading


    mov si,print_message
    call print

    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh,bh
    mul bx
    add ax, [bdb_reserved_sectors] ;= lba of root directory
    push ax

    mov ax, [bdb_dir_entires_count]
    shl ax, 5
    xor dx,dx
    div word [bdb_bytes_per_sector]


    test dx,dx
    jz rootDirectory
    inc ax
    
rootDirectory:
    mov cl,al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx,buffer
    call disk_reading

    xor bx,bx

    mov di, buffer

SearchKernel:
    mov si, kernel_name
    mov cx, 11
    push di
    repe cmpsb
    pop di 
    je foundKernel

    add di,32
    inc bx
    cmp bx, [bdb_dir_entires_count]
    jl SearchKernel

    jmp kernelNotFound

kernelNotFound:
    mov si, kernel_not_found
    call print
    hlt
    jmp halt

foundKernel:
    mov ax, [di+26]
    mov [kernel_cluster], ax

    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]

    call disk_reading

    mov bx, kernel_load_segment
    mov es,bx
    mov bx, kernel_load_offset

loadKernel:
    mov ax,[kernel_cluster]
    mov ax,31
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_reading
    add bx, [bdb_bytes_per_sector]

    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx


    mov si, buffer
    add si,ax
    mov ax, [ds:si]

    or dx,dx
    jz even 

odd:
    shr ax,4
    jmp nextClusterAfter
even:
    and ax, 0x0FFF

nextClusterAfter:
      cmp ax, 0x0FF8
      jae kernelLoaded

      mov [kernel_cluster], ax
      jmp loadKernel

kernelLoaded:
    mov dl, [ebr_drive_number]
    mov ax, kernel_load_segment
    mov ds,ax
    mov es,ax

    jmp kernel_load_segment:kernel_load_offset

    hlt

halt:
    jmp halt

; input lba index in ax
; cx [1-5 bits] = sector number
; cx [6-8 bits] = cylinder number
; dh = head number
; formulas in notes
lba_to_chs:
    push ax
    push dx

    xor dx,dx
    div word [bdb_sectors_per_track]
    inc dx   ;=sector
    mov cx, dx

    xor dx,dx
    div word [bdb_heads]

    mov dh, dl ;=head
    mov ch,al
    shl ah,6
    or cl,ah ;=cylinder

    pop ax
    mov dl,al
    pop ax
    ret


disk_reading:
    push ax
    push bx
    push cx
    push dx
    push di

    call lba_to_chs
    mov ah, 0x2
    mov di,3

retry: 
    stc 
    int 13h
    jnc doneReading

    call diskReset

    dec di
    test di, di
    jnz retry

failDiskReading:
    mov si, read_fail
    call print
    hlt
    jmp halt

diskReset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc failDiskReading
    popa
    ret
 
doneReading:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print:
    push si
    push ax
    push bx

print_loop:
    lodsb
    or al,al
    jz print_done
    mov ah,0x0E
    mov bx,0
    int 0x10
    jmp print_loop

print_done:
    pop bx
    pop ax
    pop si
    ret

print_message: db "This is Swastic's bootloader!", 0x0D, 0x0A, 0 
read_fail: db "Disk Reading failed", 0x0D, 0x0A, 0
kernel_name db "KERNEL  BIN"
kernel_not_found: db "KERNEL.BIN not found", 0x0D, 0x0A, 0
kernel_cluster: dw 0

kernel_load_segment equ 0x2000
kernel_load_offset equ 0x0

times 510-($-$$) db 0
dw 0xAA55


buffer: