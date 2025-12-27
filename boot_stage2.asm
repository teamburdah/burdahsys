; boot_stage2.asm
; Code generated with assistance from DeepSeek AI
[BITS 16]
[ORG 0x7E00]

stage2_start:
    ; Cetak pesan stage2
    mov si, msg_stage2
    call print_string
    
    ; Hitung lokasi struktur FAT16
    call calculate_fat_params
    
    ; Load FAT ke memory
    mov ax, [fat_lba]
    mov cx, [sectors_per_fat]
    mov bx, FAT_BUFFER          ; 0x8000
    call read_sectors
    jc .disk_error
    
    ; Load Root Directory
    mov ax, [root_lba]
    mov cx, [root_sectors]
    mov bx, ROOT_BUFFER         ; 0x9000
    call read_sectors
    jc .disk_error
    
    ; Cari BURDAH.SYS as kernel
    mov di, ROOT_BUFFER
    mov cx, [bpb_root_entries]
.search_kernel:
    push di
    push cx
    mov si, kernel_name
    mov cx, 11
    repe cmpsb
    pop cx
    pop di
    je .found_kernel
    
    add di, 32                  ; Next directory entry
    loop .search_kernel
    
    ; Kernel tidak ditemukan
    mov si, msg_no_kernel
    call print_string
    jmp $
    
.found_kernel:
    ; Dapatkan cluster pertama kernel
    mov ax, [di + 26]           ; First cluster (offset 26)
    mov [current_cluster], ax
    mov word [load_segment], KERNEL_LOAD_SEG  ; 0x1000
    
    ; Load kernel ke memory
.load_cluster_loop:
    ; Konversi cluster ke LBA
    mov ax, [current_cluster]
    sub ax, 2                   ; Cluster dimulai dari 2
    xor bh, bh
    mov bl, [bpb_sect_per_clust]
    mul bx
    add ax, [data_lba]
    
    ; Load cluster
    mov cx, [bpb_sect_per_clust]
    mov bx, [load_offset]
    call read_sectors
    jc .disk_error
    
    ; Update pointer
    mov ax, 512
    mul cx                      ; DX:AX = bytes read
    add [load_offset], ax
    
    ; Cek overflow segment
    cmp word [load_offset], 0xF000
    jb .next_cluster
    
    ; Adjust segment
    add word [load_segment], 0x1000
    mov word [load_offset], 0
    
.next_cluster:
    ; Cari next cluster di FAT
    mov ax, [current_cluster]
    mov bx, 2
    mul bx                      ; FAT16: 2 bytes per entry
    mov si, FAT_BUFFER
    add si, ax
    mov ax, [si]                ; Next cluster
    
    ; Cek EOF
    cmp ax, 0xFFF8
    jb .continue_load
    
    ; Siap masuk protected mode!
    call enable_a20
    call load_gdt
    cli
    
    ; Switch to protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump untuk flush pipeline
    jmp CODE_SEG:protected_mode

.continue_load:
    mov [current_cluster], ax
    jmp .load_cluster_loop

.disk_error:
    mov si, msg_disk_error
    call print_string
    jmp $

;----------------------------------------------------------
; Fungsi: Hitung parameter FAT16
;----------------------------------------------------------
calculate_fat_params:
    ; FAT start = reserved sectors
    mov ax, [bpb_reserved_sect]
    mov [fat_lba], ax
    
    ; Root directory start = reserved + (fat_copies * sectors_per_fat)
    mov ax, [bpb_sect_per_fat]
    mov bl, [bpb_fat_copies]
    xor bh, bh
    mul bx
    add ax, [bpb_reserved_sect]
    mov [root_lba], ax
    
    ; Root directory size = (root_entries * 32) / 512
    mov ax, [bpb_root_entries]
    shl ax, 5                   ; * 32
    xor dx, dx
    mov bx, [bpb_bytes_per_sect]
    div bx
    mov [root_sectors], ax
    
    ; Data area start = root_lba + root_sectors
    add ax, [root_lba]
    mov [data_lba], ax
    
    ; Sectors per FAT
    mov ax, [bpb_sect_per_fat]
    mov [sectors_per_fat], ax
    ret

;----------------------------------------------------------
; Fungsi: Enable A20 Line
;----------------------------------------------------------
enable_a20:
    ; Try BIOS method first
    mov ax, 0x2401
    int 0x15
    ret

;----------------------------------------------------------
; GDT untuk Protected Mode
;----------------------------------------------------------
load_gdt:
    lgdt [gdt_descriptor]
    ret

gdt_start:
    dq 0x0000000000000000      ; Null descriptor
    
    ; Code segment (0x08)
    dw 0xFFFF                  ; Limit 0-15
    dw 0x0000                  ; Base 0-15
    db 0x00                    ; Base 16-23
    db 0x9A                    ; P=1, DPL=0, Type=Code, Execute/Read
    db 0xCF                    ; G=1, D=1, Limit 16-19=0xF
    db 0x00                    ; Base 24-31
    
    ; Data segment (0x10)
    dw 0xFFFF                  ; Limit 0-15
    dw 0x0000                  ; Base 0-15
    db 0x00                    ; Base 16-23
    db 0x92                    ; P=1, DPL=0, Type=Data, Read/Write
    db 0xCF                    ; G=1, D=1, Limit 16-19=0xF
    db 0x00                    ; Base 24-31
    
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

;----------------------------------------------------------
; Protected Mode Entry
;----------------------------------------------------------
[BITS 32]
protected_mode:
    ; Setup segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Setup stack
    mov esp, 0x90000
    
    ; Clear screen (VGA text mode)
    mov edi, 0xB8000
    mov ecx, 80*25
    mov eax, 0x0F200F20        ; Black bg, White fg, Space char
    rep stosd
    
    ; Cetak pesan protected mode
    mov esi, msg_pm
    mov edi, 0xB8000
    mov ah, 0x0F               ; White on black
.pm_print:
    lodsb
    or al, al
    jz .jump_kernel
    stosw
    jmp .pm_print
    
.jump_kernel:
    ; Jump ke kernel di 0x10000 (640KB)
    ; Kernel di-load di 0x1000:0x0000 = 0x10000
    jmp CODE_SEG:0x10000

;----------------------------------------------------------
; Data dan Konstanta
;----------------------------------------------------------
[BITS 16]

; Konstanta
FAT_BUFFER      equ 0x8000
ROOT_BUFFER     equ 0x9000
KERNEL_LOAD_SEG equ 0x1000      ; Segment untuk load kernel
CODE_SEG        equ 0x08
DATA_SEG        equ 0x10

; Variabel
fat_lba         dw 0
root_lba        dw 0
root_sectors    dw 0
data_lba        dw 0
sectors_per_fat dw 0
current_cluster dw 0
load_segment    dw 0
load_offset     dw 0

; Pesan
msg_stage2      db "Starting Burdah...", 13, 10, 0
msg_no_kernel   db "BURDAH.SYS not found!", 13, 10, 0
msg_disk_error  db "Disk read error!", 13, 10, 0
kernel_name     db "BURDAH  SYS"

; Include fungsi dari stage1 (read_sectors, print_string)
%include "boot_common.asm"

; Padding stage2 (max 2KB)
times 2048-($-$$) db 0
