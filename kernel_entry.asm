; kernel_entry.asm
; Code generated with assistance from DeepSeek AI
[BITS 32]
global _start
extern kernel_main

section .text
_start:
    ; Setup stack pointer
    mov esp, stack_top
    
    ; Call C kernel main
    call kernel_main
    
    ; Jika kernel_main return, halt
    cli
.halt:
    hlt
    jmp .halt

section .bss
align 16
stack_bottom:
    resb 16384  ; 16KB stack
stack_top:
