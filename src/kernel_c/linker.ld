/* Nyx Kernel Linker Script */
OUTPUT_FORMAT("binary")
ENTRY(_start)

/* Kernel is loaded at 0x10000 (64KB mark) by the bootloader */
SECTIONS
{
    . = 0x10000;
    
    .text : {
        *(.text)
    }
    
    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }
    
    .bss : {
        *(.bss)
    }
}