use16
cpu 8086
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
	
	mov word [text_x], 0
	mov word [text_y], 0
	mov word [text_w], 80
	mov word [text_h], 25
	mov word [text_seg], 0xB800
	mov byte [text_attr], 01Bh

	mov si, kernel_greet
	call _printf
.loop:
	mov al, 0Dh
	call _putc
	mov al, '>'
	call _putc

	mov bx, 126
	mov di, kernel_buffer.keyboard
	call _gets
	
	mov al, 0Dh
	call _putc
	
	mov si, kernel_buffer.keyboard
	mov di, kernel_buffer.fat12
	call _strfat12
	
	mov si, kernel_buffer.fat12
	mov ax, 32768
	call _fopen
	jnc short .file_ok
	jc short .no_file
	
	jmp short .loop
.file_ok:
	mov si, kernel_program_start
	call _printf

	call 32768
	
	mov si, kernel_program_end
	call _printf
	jmp short .loop
.no_file:
	mov si, kernel_no_program
	call _printf
	jmp short .loop

root_dir_entries		dw 224
bytes_per_sector		dw 512
sectors_per_track		dw 18
sides					dw 2
device_number			db 0

kernel_greet			db "LeafDOS v0.1",0x0D
						db "Kernel hot-date: ",__DATE__,0x0D
						db 0x00
						
kernel_program_start	db "Starting program",0x0D
						db 0x00

kernel_program_end		db "Program finished",0x0D
						db 0x00
						
kernel_no_program		db "File not found",0x0D
						db 0x00

kernel_buffer:
	.keyboard			times 128 db 0
	.fat12				times 128 db 0

%include "src/internal.asm"
