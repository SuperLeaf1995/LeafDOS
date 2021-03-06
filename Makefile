ARCH = i386
TARGET = $(ARCH)-elf
CROSSPATH = /home/$(USER)/opt/gcc-$(TARGET)/bin

CFLAGS =	-Wall					\
			-Wextra					\
			-Wtraditional			\
			-Wdouble-promotion		\
			-ffreestanding			\
			-I$(SRC_DIR)/libc		\
			-I$(SRC_DIR)
			
CC = $(CROSSPATH)/$(TARGET)-gcc

LDFLAGS = -nostdlib
LD = $(CROSSPATH)/$(TARGET)-ld

AS = $(CROSSPATH)/$(TARGET)-as
AR = $(CROSSPATH)/$(TARGET)-ar

SRC_DIR = src
OUT_DIR = bin
DISK_DIR = disk

build: $(DISK_DIR)/LeafDOS.iso
	mkdir -p bin disk disk/boot disk/boot/grub

clean:
	rm -rf bin/* disk/*

run: build
	qemu-system-i386 -cdrom $(DISK_DIR)/LeafDOS.iso -m 32M
	
init_disk: $(OUT_DIR)/kernel.elf
	grub-file --is-x86-multiboot $(OUT_DIR)/kernel.elf
	cp $(OUT_DIR)/kernel.elf $(DISK_DIR)/boot/kernel.elf
	cp $(SRC_DIR)/boot/grub.cfg $(DISK_DIR)/boot/grub/grub.cfg

$(OUT_DIR)/kernel.elf: $(OUT_DIR)/entry.o $(OUT_DIR)/kernel.o
	$(LD) $(LDFLAGS) -T $(SRC_DIR)/linker.ld $^ -o $@

$(OUT_DIR)/entry.o: $(SRC_DIR)/kernel/entry.s
	$(AS) $< -o $@

$(OUT_DIR)/kernel.o: $(SRC_DIR)/kernel/kernel.c
	$(CC) $(CFLAGS) -x c -c $< -o $@
	
$(DISK_DIR)/LeafDOS.iso: init_disk $(OUT_DIR)/kernel.elf $(SRC_DIR)/boot/grub.cfg $(OUT_DIR)/libc.a
	grub-mkrescue -o $@ $(DISK_DIR)
