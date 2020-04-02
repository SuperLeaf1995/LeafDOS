use16
cpu 186
org 0

buffer			equ	24576

start:
	xor ax, ax
	cli
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh
	sti
	cld
	mov ax, 0500h
	mov fs, ax
	mov gs, ax
	mov es, ax
	mov ds, ax
	
	test dl, dl ;get drive information
	je short .old
	mov [device_number], dl ;set dl to device
	mov ah, 8 ;issue interrupt
	int 13h
	jc short .old ;if error reboot
	and cx, 3Fh ;mask out bits of cx
	mov [sectors_per_track], cx
	;movzx dx, dh ;sides are dh+1
	mov dl, dh ;sides are dh+1
	xor dh, dh
	inc dx
	mov [sides], dx
.old:
	;xor eax eax ;for old BIOSes

	mov si, kernel_greet
	call print_string
.loop:
	mov al, '>'
	call print_char

	mov bx, 126
	mov di, kernel_buffer.keyboard
	call get_input
	
	mov si, kernel_buffer.keyboard
	mov di, kernel_buffer.fat12
	call string_to_fat12
	
	mov al, 0Dh
	call print_char
	mov al, 0Ah
	call print_char
	
	mov si, kernel_buffer.fat12
	mov ax, 32768
	call read_file
	jnc short .file_ok
	
	jmp short .loop
.file_ok:
	mov si, kernel_greet
	call print_string

	call 32768
	
	mov si, kernel_greet
	call print_string
	jmp short .loop

root_dir_entries		dw 224
bytes_per_sector		dw 512
sectors_per_track		dw 18
sides					dw 2
device_number			db 0

kernel_greet			db "LeafDOS v0.1",0x0D,0x0A
						db "Kernel hot-date: ",__DATE__,0x0D,0x0A
						db 0x00
kernel_buffer:
	.keyboard			times 128 db 0
	.fat12				times 128 db 0

%include "src/internal.asm"
