void print_string(const char* str);
void print_char(char c);

void kernel_main(void) {
    print_string("\r\n");
    print_string("Hello from C Kernel!\r\n");
    print_string("JazzOS C Kernel v0.1\r\n");
    print_string("Kernel loaded successfully!\r\n");
    
    // Halt
    while(1) {
        __asm__ __volatile__("hlt");
    }
}

void print_char(char c) {
    __asm__ __volatile__(
        "mov $0x0E, %%ah\n"
        "mov $0, %%bh\n"
        "int $0x10\n"
        : 
        : "a"(c)
    );
}

void print_string(const char* str) {
    while(*str) {
        print_char(*str);
        str++;
    }
}
