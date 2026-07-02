; Global Descriptor Table - flat 32-bit model: null, code, data.
; Both code and data span all 4 GB from base 0, so addresses become plain
; 32-bit offsets. gdt_install points the CPU at this table (does NOT switch mode).

gdt_start:

gdt_null:                        ; entry 0 (selector 0x00) - required, must be zero
    dq 0

gdt_code:                        ; entry 1 (selector 0x08) - ring0 32-bit code
    dw 0xFFFF                    ; limit 15:0
    dw 0x0000                    ; base 15:0
    db 0x00                      ; base 23:16
    db 10011010b                 ; access 0x9A: P=1 DPL=0 S=1 E=1 DC=0 RW=1 A=0
    db 11001111b                 ; 0xCF: flags G=1 DB=1 L=0 AVL=0 | limit 19:16=0xF
    db 0x00                      ; base 31:24

gdt_data:                        ; entry 2 (selector 0x10) - ring0 32-bit data
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                 ; access 0x92: same as code but E=0 (data), RW=1 (writable)
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:                  ; the 6-byte operand lgdt reads
    dw gdt_end - gdt_start - 1   ; limit = table size - 1
    dd gdt_start                  ; base = linear address of the table

CODE_SEG equ gdt_code - gdt_start   ; = 0x08 (offset of code entry = its selector)
DATA_SEG equ gdt_data - gdt_start   ; = 0x10

gdt_install:
    lgdt [gdt_descriptor]        ; load GDTR with (limit, base)
    ret
