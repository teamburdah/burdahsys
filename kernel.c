// kernel.c
// Code generated with assistance from DeepSeek AI
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

// VGA text buffer
volatile uint16_t* vga_buffer = (uint16_t*)0xB8000;

// Current cursor position
uint32_t cursor_x = 0;
uint32_t cursor_y = 0;

// VGA color constants
enum vga_color {
    COLOR_BLACK = 0,
    COLOR_BLUE = 1,
    COLOR_GREEN = 2,
    COLOR_CYAN = 3,
    COLOR_RED = 4,
    COLOR_MAGENTA = 5,
    COLOR_BROWN = 6,
    COLOR_LIGHT_GREY = 7,
    COLOR_DARK_GREY = 8,
    COLOR_LIGHT_BLUE = 9,
    COLOR_LIGHT_GREEN = 10,
    COLOR_LIGHT_CYAN = 11,
    COLOR_LIGHT_RED = 12,
    COLOR_LIGHT_MAGENTA = 13,
    COLOR_LIGHT_BROWN = 14,
    COLOR_WHITE = 15,
};

// Create color byte
static inline uint8_t make_color(enum vga_color fg, enum vga_color bg) {
    return fg | (bg << 4);
}

// Create VGA entry
static inline uint16_t make_vgaentry(char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

// Clear screen
void clear_screen(uint8_t color) {
    uint16_t blank = make_vgaentry(' ', color);
    for (uint32_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = blank;
    }
    cursor_x = 0;
    cursor_y = 0;
}

// Put character at position
void putchar_at(char c, uint8_t color, uint32_t x, uint32_t y) {
    vga_buffer[y * VGA_WIDTH + x] = make_vgaentry(c, color);
}

// Scroll screen
void scroll_screen() {
    for (uint32_t y = 1; y < VGA_HEIGHT; y++) {
        for (uint32_t x = 0; x < VGA_WIDTH; x++) {
            vga_buffer[(y - 1) * VGA_WIDTH + x] = 
                vga_buffer[y * VGA_WIDTH + x];
        }
    }
    
    // Clear last line
    uint16_t blank = make_vgaentry(' ', make_color(COLOR_WHITE, COLOR_BLACK));
    for (uint32_t x = 0; x < VGA_WIDTH; x++) {
        vga_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = blank;
    }
}

// Put character with cursor handling
void putchar(char c) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\t') {
        cursor_x = (cursor_x + 4) & ~3;
    } else {
        putchar_at(c, make_color(COLOR_WHITE, COLOR_BLACK), cursor_x, cursor_y);
        cursor_x++;
    }
    
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }
    
    if (cursor_y >= VGA_HEIGHT) {
        scroll_screen();
        cursor_y = VGA_HEIGHT - 1;
    }
}

// Print string
void print_string(const char* str) {
    while (*str) {
        putchar(*str++);
    }
}

// Kernel main function
void kernel_main() {
    // Clear screen
    clear_screen(make_color(COLOR_WHITE, COLOR_BLUE));
    
    // Print welcome message
    print_string("MyOS 32-bit Kernel Booted!\n");
    print_string("Booted from FAT16 filesystem\n");
    print_string("Kernel loaded at 0x10000\n\n");
    
    // System information
    print_string("System Status:\n");
    print_string("- Running in 32-bit protected mode\n");
    print_string("- VGA text mode: 80x25\n");
    print_string("- Filesystem: FAT16\n");
    print_string("- Disk: 32MB virtual image\n");
    
    // Draw separator
    print_string("\n");
    for (int i = 0; i < VGA_WIDTH; i++) {
        putchar('=');
    }
    print_string("\n");
    
    // Test pattern
    print_string("\nColor Test: ");
    for (int i = 0; i < 16; i++) {
        putchar_at(' ', make_color(i, COLOR_BLACK), 13 + i * 2, cursor_y);
    }
    
    print_string("\n\nReady. Press any key...\n");
    
    // Halt (nanti bisa diganti dengan interrupt handler)
    while (1) {
        // Untuk sekarang, infinite loop
        // Nanti bisa tambah keyboard interrupt
    }
}
