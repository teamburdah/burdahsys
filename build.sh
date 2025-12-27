#!/bin/bash
# build.sh - Build MyOS dari nol

echo "=== Building MyOS ==="

# Build bootloader
echo "1. Assembling bootloader..."
nasm -f bin boot_stage1.asm -o boot_stage1.bin
nasm -f bin boot_stage2.asm -o boot_stage2.bin

# Build kernel
echo "2. Building kernel..."
nasm -f elf32 kernel_entry.asm -o kernel_entry.o
i686-elf-gcc -c kernel.c -o kernel.o -ffreestanding -std=gnu99 -masm=intel -m32
i686-elf-ld -T linker.ld -o kernel.bin -m elf_i386 kernel_entry.o kernel.o

# Create disk image
echo "3. Creating disk image..."
dd if=/dev/zero of=myos.img bs=1M count=32 status=none

# Create FAT16 filesystem
echo "4. Formatting FAT16..."
mkfs.fat -F 16 -S 512 -s 1 -R 512 myos.img > /dev/null 2>&1

# Write bootloader to MBR
echo "5. Installing bootloader..."
dd if=boot_stage1.bin of=myos.img conv=notrunc status=none

# Write stage2 to sector 1-4
dd if=boot_stage2.bin of=myos.img bs=512 seek=1 conv=notrunc status=none

# Copy kernel to filesystem
echo "6. Copying kernel..."
mcopy -i myos.img kernel.bin ::KERNEL.BIN

echo "7. Creating ISO (optional)..."
mkdir -p iso
cp myos.img iso/
genisoimage -o myos.iso -b myos.img iso/ > /dev/null 2>&1

echo "=== Build Complete ==="
echo "Disk image: myos.img (32MB FAT16)"
echo "ISO image:  myos.iso"
echo ""
echo "Test dengan: qemu-system-i386 -drive file=myos.img,format=raw -m 32M"
