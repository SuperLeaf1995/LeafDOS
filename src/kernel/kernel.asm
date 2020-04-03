use16
cpu 8086
org 0

SEG_KERNEL			equ 0500h
SEG_BUFFER			equ	4000h
SEG_PROGRAM			equ 8000h

jmp short start

jmp near _printf		;000
jmp near _putc			;003
jmp near _memcpy		;006
jmp near _memcmp		;009
jmp near _strcmp		;012
jmp near _strcpyup		;015
jmp near _strup			;018
jmp near _fopen			;021
jmp near _flist			;024
jmp near _strfat12		;027
jmp near _dumpregs		;030
jmp near _dissasembly	;033

start:
	xor ax, ax
	cli ;set the stack
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh
	sti
	cld
	mov ax, SEG_KERNEL ;segmentate to
	mov es, ax ;all data and extended segment into the
	mov ds, ax ;kernel segment
	
	clc ;check if we have engough memory for our
	int 12h ;programs and buffers
	jc .not_engough_memory
	
	cmp ax, 64
	jl .not_engough_memory
	
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
	
	call near _clrscr

	mov ax, 0
	push ax
	mov ax, 2
	push ax
	mov si, kernel_greet
	call near _printf
.loop:
	mov al, 0Dh
	call near _putc
	mov al, '>'
	call near _putc
	
	call near update_cursor_to_curr

	mov bx, 126
	mov di, kernel_buffer.keyboard
	call near _gets
	
	mov al, 0Dh
	call near _putc
	
	mov si, kernel_buffer.keyboard
	mov di, kernel_buffer.fat12
	call near _strfat12
	
	mov si, kernel_buffer.fat12
	mov ax, SEG_PROGRAM
	call near _fopen
	jnc short .file_ok
	jc short .no_file
	
	jmp short .loop
.file_ok:
	mov si, kernel_program_start
	call near _printf

	call SEG_PROGRAM
	
	mov si, kernel_program_end
	call near _printf
	jmp short .loop
.no_file:
	mov si, kernel_no_program
	call near _printf
	jmp short .loop
	
.not_engough_memory:
	mov si, kernel_memory_error
	call near _printf
	jmp short .loop

root_dir_entries		dw 224
bytes_per_sector		dw 512
sectors_per_track		dw 18
sides					dw 2
device_number			db 0

kernel_greet			db "LeafDOS v%x.%x",0x0D
						db "Kernel hot-date: ",__DATE__,0x0D
						db 0x00
						
kernel_program_start	db "Starting program",0x0D
						db 0x00

kernel_program_end		db "Program finished",0x0D
						db 0x00
						
kernel_no_program		db "File not found",0x0D
						db 0x00

kernel_memory_error		db "LeafDOS requires atleast 64 KB of memory to run",0x0D
						db 0x00

kernel_buffer:
	.keyboard			times 128 db 0
	.fat12				times 128 db 0

%include "debug.asm"
%include "stdio.asm"
