/* linker.ld */
ENTRY(_start)

SECTIONS {
    /* Kernel di-load di 0x10000 (640KB) */
    . = 0x10000;
    
    /* Text section */
    .text : {
        *(.text)
    }
    
    /* Read-only data */
    .rodata : {
        *(.rodata*)
    }
    
    /* Read-write data (initialized) */
    .data : {
        *(.data)
    }
    
    /* Read-write data (uninitialized) dan stack */
    .bss : {
        *(COMMON)
        *(.bss)
    }
    
    /* End of kernel */
    _end = .;
}
