/* ============================================================================
 * NYX KERNEL - Main C Entry Point
 * ============================================================================
 * This kernel runs in 32-bit protected mode. BIOS interrupts are NOT available.
 * We use direct VGA memory writes for screen output.
 * ============================================================================ */

/* VGA Text Mode Buffer */
#define VGA_BUFFER  0xB8000
#define VGA_WIDTH   80
#define VGA_HEIGHT  25

/* VGA Colors */
#define VGA_BLACK         0x0
#define VGA_BLUE          0x1
#define VGA_GREEN         0x2
#define VGA_CYAN          0x3
#define VGA_RED           0x4
#define VGA_MAGENTA       0x5
#define VGA_BROWN         0x6
#define VGA_LIGHT_GRAY    0x7
#define VGA_DARK_GRAY     0x8
#define VGA_LIGHT_BLUE    0x9
#define VGA_LIGHT_GREEN   0xA
#define VGA_LIGHT_CYAN    0xB
#define VGA_LIGHT_RED     0xC
#define VGA_LIGHT_MAGENTA 0xD
#define VGA_YELLOW        0xE
#define VGA_WHITE         0xF

/* Global cursor position */
static int cursor_x = 0;
static int cursor_y = 2;  /* Start at line 2 (line 0-1 used by kernel entry) */

/* VGA buffer pointer */
static unsigned short* vga_buffer = (unsigned short*)VGA_BUFFER;

/* Create VGA character with color */
static inline unsigned short vga_entry(char c, unsigned char fg, unsigned char bg) {
    return (unsigned short)c | ((unsigned short)(fg | (bg << 4)) << 8);
}

/* Put character at specific position */
void vga_putchar_at(char c, int x, int y, unsigned char fg, unsigned char bg) {
    vga_buffer[y * VGA_WIDTH + x] = vga_entry(c, fg, bg);
}

/* Scroll screen up one line */
void vga_scroll(void) {
    /* Move all lines up by one */
    for (int y = 0; y < VGA_HEIGHT - 1; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            vga_buffer[y * VGA_WIDTH + x] = vga_buffer[(y + 1) * VGA_WIDTH + x];
        }
    }
    /* Clear last line */
    for (int x = 0; x < VGA_WIDTH; x++) {
        vga_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = vga_entry(' ', VGA_LIGHT_GRAY, VGA_BLACK);
    }
}

/* Print single character with color */
void print_char_color(char c, unsigned char fg, unsigned char bg) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\t') {
        cursor_x = (cursor_x + 8) & ~7;  /* Align to next 8-column boundary */
    } else {
        vga_putchar_at(c, cursor_x, cursor_y, fg, bg);
        cursor_x++;
    }
    
    /* Handle line wrap */
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }
    
    /* Handle scroll */
    if (cursor_y >= VGA_HEIGHT) {
        vga_scroll();
        cursor_y = VGA_HEIGHT - 1;
    }
}

/* Print single character (default color) */
void print_char(char c) {
    print_char_color(c, VGA_LIGHT_GREEN, VGA_BLACK);
}

/* Print string with color */
void print_string_color(const char* str, unsigned char fg, unsigned char bg) {
    while (*str) {
        print_char_color(*str, fg, bg);
        str++;
    }
}

/* Print string (default color) */
void print_string(const char* str) {
    print_string_color(str, VGA_LIGHT_GREEN, VGA_BLACK);
}

/* Print hexadecimal number */
void print_hex(unsigned int value) {
    char hex_chars[] = "0123456789ABCDEF";
    char buffer[11];  /* "0x" + 8 hex digits + null */
    buffer[0] = '0';
    buffer[1] = 'x';
    buffer[10] = '\0';
    
    for (int i = 9; i >= 2; i--) {
        buffer[i] = hex_chars[value & 0xF];
        value >>= 4;
    }
    
    print_string(buffer);
}

/* Print decimal number */
void print_dec(int value) {
    if (value < 0) {
        print_char('-');
        value = -value;
    }
    
    if (value == 0) {
        print_char('0');
        return;
    }
    
    char buffer[12];
    int i = 0;
    
    while (value > 0) {
        buffer[i++] = '0' + (value % 10);
        value /= 10;
    }
    
    /* Print in reverse */
    while (i > 0) {
        print_char(buffer[--i]);
    }
}

/* ============================================================================
 * KERNEL MAIN ENTRY POINT
 * ============================================================================ */
void kernel_main(void) {
    /* Print welcome banner */
    print_string_color("==============================================\n", VGA_CYAN, VGA_BLACK);
    print_string_color("         NYX OS - Kernel Loaded!              \n", VGA_WHITE, VGA_BLACK);
    print_string_color("==============================================\n", VGA_CYAN, VGA_BLACK);
    
    print_string("\n");
    print_string("Welcome to Nyx Operating System!\n");
    print_string("Kernel is running in 32-bit protected mode.\n");
    print_string("\n");
    
    /* Print some system info */
    print_string_color("[INFO] ", VGA_YELLOW, VGA_BLACK);
    print_string("VGA Text Mode: 80x25\n");
    
    print_string_color("[INFO] ", VGA_YELLOW, VGA_BLACK);
    print_string("Kernel loaded at: ");
    print_hex(0x10000);
    print_string("\n");
    
    print_string_color("[INFO] ", VGA_YELLOW, VGA_BLACK);
    print_string("Stack pointer at: ");
    print_hex(0x90000);
    print_string("\n");
    
    print_string("\n");
    print_string_color("[OK] ", VGA_LIGHT_GREEN, VGA_BLACK);
    print_string("System initialized successfully!\n");
    
    print_string("\n");
    print_string_color("System halted. Press reset to restart.\n", VGA_DARK_GRAY, VGA_BLACK);
    
    /* Halt the CPU */
    while (1) {
        __asm__ __volatile__("hlt");
    }
}