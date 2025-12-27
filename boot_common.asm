; boot_common.asm
; Code generated with assistance from DeepSeek AI 🤫
[BITS 16]

;----------------------------------------------------------
; print_string: Print string with BIOS interrupt
; Input:  SI = pointer to null-terminated string
;----------------------------------------------------------
print_string:
    pusha
    mov ah, 0x0E
.print_char:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_char
.done:
    popa
    ret

;----------------------------------------------------------
; read_sectors: Same as stage1 but imported here
;----------------------------------------------------------
read_sectors:
    ; ... (sama seperti di stage1)
    ret

; Data dari BPB (harus sama dengan stage1)
bpb_reserved_sect  dw 1
bpb_fat_copies     db 2
bpb_root_entries   dw 512
bpb_bytes_per_sect dw 512
bpb_sect_per_clust db 1
bpb_sect_per_fat   dw 256
