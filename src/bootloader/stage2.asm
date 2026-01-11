; ============================================================================
; STAGE 2 BOOTLOADER (Simplified)
; ============================================================================
; Loaded by Stage 1 at 0x7E00. This stage:
; 1. Loads kernel from sector 17 to 0x10000
; 2. Enables A20 line
; 3. Sets up GDT and switches to 32-bit protected mode
; 4. Jumps to kernel
; ============================================================================

[bits 16]
[org 0x7E00]

KERNEL_SECTOR   equ 17          ; Kernel starts at sector 17
KERNEL_SECTORS  equ 32          ; Read up to 16KB of kernel
KERNEL_SEGMENT  equ 0x1000      ; Load kernel at 0x10000

stage2_start:
    ; Print '2' immediately to show we're executing
    mov ah, 0x0E
    mov al, '2'
    int 0x10

    ; Setup segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Save boot drive
    mov [boot_drive], dl

    mov si, msg_stage2
    call print_string

    ; ========================================================================
    ; Load Kernel from sector 17
    ; ========================================================================
    mov si, msg_loading_kernel
    call print_string

    ; Set destination segment
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor bx, bx                  ; ES:BX = 0x1000:0x0000 = 0x10000

    ; Read kernel sectors
    mov ax, KERNEL_SECTOR       ; Starting LBA
    mov cx, KERNEL_SECTORS      ; Number of sectors
    call read_sectors

    mov si, msg_kernel_loaded
    call print_string

    ; ========================================================================
    ; Enable A20 Line
    ; ========================================================================
    mov si, msg_a20
    call print_string
    call enable_a20
    mov si, msg_ok
    call print_string

    ; ========================================================================
    ; Switch to Protected Mode
    ; ========================================================================
    mov si, msg_pm
    call print_string

    cli                         ; Disable interrupts
    lgdt [gdt_descriptor]       ; Load GDT

    ; Set PE bit in CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to protected mode
    jmp CODE_SEG:protected_mode_entry

; ============================================================================
; Read Sectors (LBA to CHS)
; Input: AX = LBA, CX = count, ES:BX = buffer
; ============================================================================
read_sectors:
    pusha
    mov bp, cx                  ; Save count

.loop:
    push ax                     ; Save LBA

    ; LBA to CHS conversion
    xor dx, dx
    mov cx, 18                  ; Sectors per track
    div cx                      ; AX = track, DX = sector-1
    inc dx
    mov cl, dl                  ; CL = sector (1-18)

    xor dx, dx
    mov cx, 2                   ; Heads
    div cx                      ; AX = cylinder, DX = head
    mov ch, al                  ; CH = cylinder
    mov dh, dl                  ; DH = head

    ; Read 1 sector
    mov ah, 0x02
    mov al, 1
    mov dl, [boot_drive]
    int 0x13
    jc .error

    pop ax
    inc ax                      ; Next LBA
    add bx, 512                 ; Next buffer position
    dec bp
    jnz .loop

    popa
    ret

.error:
    mov si, msg_disk_err
    call print_string
    jmp halt

; ============================================================================
; Enable A20 Line
; ============================================================================
enable_a20:
    ; Try BIOS first
    mov ax, 0x2401
    int 0x15
    jnc .done

    ; Fast A20 method
    in al, 0x92
    or al, 2
    out 0x92, al

.done:
    ret

; ============================================================================
; Print String (Real Mode)
; ============================================================================
print_string:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    popa
    ret

halt:
    cli
    hlt
    jmp halt

; ============================================================================
; GDT
; ============================================================================
gdt_start:
    dq 0                        ; Null descriptor

gdt_code:
    dw 0xFFFF                   ; Limit
    dw 0x0000                   ; Base (low)
    db 0x00                     ; Base (mid)
    db 10011010b                ; Access: Present, Ring 0, Code, Readable
    db 11001111b                ; Flags: 4KB granularity, 32-bit
    db 0x00                     ; Base (high)

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                ; Access: Present, Ring 0, Data, Writable
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; ============================================================================
; Data
; ============================================================================
boot_drive:     db 0

msg_stage2:         db ' Stage2', 0x0D, 0x0A, 0
msg_loading_kernel: db 'Loading kernel...', 0
msg_kernel_loaded:  db 'OK', 0x0D, 0x0A, 0
msg_a20:            db 'A20...', 0
msg_pm:             db 'PM...', 0x0D, 0x0A, 0
msg_ok:             db 'OK', 0x0D, 0x0A, 0
msg_disk_err:       db 'DISK!', 0

; ============================================================================
; 32-bit Protected Mode Code
; ============================================================================
[bits 32]

protected_mode_entry:
    ; Setup segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Print 'P' to VGA to show we're in protected mode
    mov byte [0xB8000], 'P'
    mov byte [0xB8001], 0x0A    ; Light green

    ; Jump to kernel at 0x10000
    jmp KERNEL_SEGMENT * 16

; Pad to 8KB
times 8192-($-$$) db 0
