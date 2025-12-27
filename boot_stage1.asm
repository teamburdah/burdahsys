; boot_stage1.asm
; Code generated with assistance from DeepSeek AI
[BITS 16]
[ORG 0x7C00]

; FAT16 BPB
jmp short start
nop

bpb_oem:            db "BURDAH  "
bpb_bytes_per_sect: dw 512
bpb_sect_per_clust: db 1          ; 1 sector/cluster = 512 byte
bpb_reserved_sect:  dw 1
bpb_fat_copies:     db 2
bpb_root_entries:   dw 512
bpb_total_sects:    dw 0          ; Use large_sector_count
bpb_media_type:     db 0xF8
bpb_sect_per_fat:   dw 256        ; FAT size for 32MB disk
bpb_sect_per_track: dw 18
bpb_heads:          dw 2
bpb_hidden_sects:   dd 0
bpb_large_sect_cnt: dd 65536      ; 32MB = 65536 sectors

; Extended BPB
drive_number:       db 0x80
reserved:           db 0
signature:          db 0x29
volume_id:          dd 0x12345678
volume_label:       db "DISK32     "
file_system:        db "FAT16   "

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Save drive number
    mov [drive_number], dl
    
    ; Calculate data structures location
    ; 1. Load Stage2 (at sector 1, right after boot sector)
    mov ax, 1                      ; LBA 1
    mov cx, 4                      ; Load 4 sectors (2KB)
    mov bx, 0x7E00                 ; Right after boot sector
    call read_sectors
    jc disk_error
    
    ; Jump to Stage2
    jmp 0x0000:0x7E00

;----------------------------------------------------------
; read_sectors: Read sectors using LBA
; Input:  AX = LBA, CX = sector count, BX = buffer
; Output: CF = 0 success, CF = 1 error
;----------------------------------------------------------
read_sectors:
    pusha
    mov [lba_sector], ax
    mov [lba_count], cx
    mov [buffer_addr], bx
    
    ; Convert LBA to CHS
    mov ax, [lba_sector]
    mov dx, 0
    div word [bpb_sect_per_track]  ; AX = cylinder, DX = sector-1
    inc dl
    mov [sector], dl               ; Sector (1-based)
    
    mov ax, [lba_sector]
    mov dx, 0
    div word [bpb_sect_per_track]  ; AX = track
    mov dx, 0
    div word [bpb_heads]           ; AX = cylinder, DX = head
    mov [head], dl
    mov [cylinder], al
    
.read_loop:
    mov ah, 0x02                   ; Read sectors
    mov al, 1                      ; Read 1 sector at a time
    mov ch, [cylinder]
    mov cl, [sector]
    mov dh, [head]
    mov dl, [drive_number]
    mov bx, [buffer_addr]
    int 0x13
    jc .error
    
    ; Update pointers
    add word [buffer_addr], 512
    inc word [lba_sector]
    
    ; Update CHS for next sector
    mov al, [sector]
    cmp al, [bpb_sect_per_track]
    jb .next_sector
    
    ; Next head
    mov byte [sector], 1
    mov al, [head]
    inc al
    cmp al, [bpb_heads]
    jb .next_head
    
    ; Next cylinder
    mov byte [head], 0
    inc byte [cylinder]
    jmp .next_iteration
    
.next_head:
    mov [head], al
    jmp .next_iteration
    
.next_sector:
    inc byte [sector]
    
.next_iteration:
    dec word [lba_count]
    jnz .read_loop
    
    popa
    clc
    ret

.error:
    popa
    stc
    ret

;----------------------------------------------------------
; Data
;----------------------------------------------------------
disk_error_msg db "Disk error!", 0

lba_sector     dw 0
lba_count      dw 0
buffer_addr    dw 0
sector         db 0
head           db 0
cylinder       db 0

disk_error:
    mov si, disk_error_msg
.print_loop:
    lodsb
    or al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print_loop
.halt:
    hlt
    jmp .halt

; Boot sector signature
times 510-($-$$) db 0
dw 0xAA55
