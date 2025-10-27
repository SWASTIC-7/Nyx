/* filepath: /home/nazr/Desktop/projects/x86_boot/src/kernel/linker.ld */
OUTPUT_FORMAT("binary")
ENTRY(_start)

SECTIONS
{
    . = 0x20000;
    
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