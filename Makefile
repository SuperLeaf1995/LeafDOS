CROSSPATH = /home/$(USER)/opt/gcc-i686/bin

CFLAGS = -Wall -Wextra -ffreestanding -I$(SRC_DIR)
CC = i686-elf-gcc

LDFLAGS = -nostdlib
LD = i686-elf-ld

AS = i686-elf-as

SRC_DIR = src
OUT_DIR = bin
DISK_DIR = disk

build: $(DISK_DIR)/leafdos.iso
	mkdir -p bin disk disk/boot disk/boot/grub

clean:
	rm -rf bin/ disk/

run: build
	qemu-system-i386 -cdrom disk/leafdos.iso -m 256M
	
init_disk: $(OUT_DIR)/kernel.elf
	grub-file --is-x86-multiboot $(OUT_DIR)/kernel.elf
	cp $(OUT_DIR)/kernel.elf $(DISK_DIR)/boot/kernel.elf
	cp $(SRC_DIR)/boot/grub.cfg $(DISK_DIR)/boot/grub/grub.cfg

$(OUT_DIR)/kernel.elf: $(OUT_DIR)/boot.o $(OUT_DIR)/kernel.o
	$(CROSSPATH)/$(LD) $(LDFLAGS) -T src/linker.ld $(OUT_DIR)/boot.o $(OUT_DIR)/kernel.o -o $(OUT_DIR)/kernel.elf

$(OUT_DIR)/boot.o: $(SRC_DIR)/boot/boot.s
	$(CROSSPATH)/$(AS) $< -o $@

$(OUT_DIR)/kernel.o: $(SRC_DIR)/kernel/kernel.c
	$(CROSSPATH)/$(CC) $(CFLAGS) -c $< -o $@
	
$(DISK_DIR)/leafdos.iso: init_disk $(OUT_DIR)/kernel.elf $(SRC_DIR)/boot/grub.cfg
	grub-mkrescue -o $(DISK_DIR)/leafdos.iso $(DISK_DIR)
