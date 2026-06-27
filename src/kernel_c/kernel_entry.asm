; ============================================================================
; KERNEL ENTRY POINT (32-bit Protected Mode)
; ============================================================================
; This is the first code executed when the bootloader jumps to the kernel.
; It sets up the environment and calls the C kernel main function.
; ============================================================================

[bits 32]
[extern kernel_main]
[global _start]

section .text

_start:
    ; We're now in 32-bit protected mode!
    ; Stack is already set up by bootloader at 0x90000
    
    ; Clear the screen first
    call clear_screen
    
    ; Print welcome message
    mov esi, msg_kernel_entry
    call print_string_pm

    ; Call C kernel main
    call kernel_main

    ; If kernel_main returns, halt
.halt:
    cli
    hlt
    jmp .halt

; ============================================================================
; Clear Screen (32-bit protected mode)
; ============================================================================
clear_screen:
    push eax
    push ecx
    push edi
    
    mov edi, 0xB8000            ; VGA text buffer
    mov ecx, 80 * 25            ; 80 columns * 25 rows
    mov ax, 0x0720              ; Space character with light gray on black
    rep stosw
    
    ; Reset cursor position
    mov dword [cursor_pos], 0
    
    pop edi
    pop ecx
    pop eax
    ret

; ============================================================================
; Print String (32-bit protected mode, direct VGA)
; Input: ESI = null-terminated string
; ============================================================================
print_string_pm:
    push eax
    push ebx
    push esi

.loop:
    lodsb                       ; Load character from ESI
    test al, al
    jz .done

    cmp al, 0x0D                ; Carriage return?
    je .cr
    cmp al, 0x0A                ; Line feed?
    je .lf

    ; Calculate VGA buffer position
    mov ebx, [cursor_pos]
    mov byte [0xB8000 + ebx*2], al
    mov byte [0xB8000 + ebx*2 + 1], 0x0A  ; Light green on black

    inc dword [cursor_pos]
    jmp .loop

.cr:
    ; Move to start of line
    mov eax, [cursor_pos]
    xor edx, edx
    mov ebx, 80
    div ebx                     ; EAX = row, EDX = column
    mul ebx                     ; EAX = start of current row
    mov [cursor_pos], eax
    jmp .loop

.lf:
    ; Move to next line
    mov eax, [cursor_pos]
    xor edx, edx
    mov ebx, 80
    div ebx                     ; EAX = row
    inc eax                     ; Next row
    mul ebx
    mov [cursor_pos], eax
    jmp .loop

.done:
    pop esi
    pop ebx
    pop eax
    ret

; ============================================================================
; Data
; ============================================================================
section .data

cursor_pos: dd 0
msg_kernel_entry: db 'Nyx Kernel Entry Point', 0x0D, 0x0A, 0

section .bss