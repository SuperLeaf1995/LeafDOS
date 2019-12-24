bits 16
org 0

;bootloader - floppy distribution

jmp short init
nop

floppy:
	.bytes_per_sector	dw 512
	.drive_number		db 0 ;changes later
	.sides				db 1 ;sides/heads
	.sectors_per_track	db 8 ;sectors/clusters
	
%include "..\io.inc"

init:
	mov ax, 07c0h ;07c0 = 8192
	add ax, 544
	cli ;disable interrupts
	mov ss, ax ;change stack segment
	mov sp, 4096
	sti
	mov ax, 07c0h
	mov ds, ax
	
	test dl, dl
	jz short old
	
	mov [floppy.drive_number], dl
	mov ah, 8
	int 13h
	jc read.error
	and cx, 3fh
	mov [floppy.sectors_per_track], cx
	movzx dx, dh
	add dx, 1
	mov [floppy.sides], dx
old:
	xor eax,eax
read:
	mov ax, 1
	call logical_to_hts
	
	mov ax, __kernel__ ;segmentate to load
	mov es, ax ;kernel into its position
	xor bx, bx ;at zero offset
	
	mov ah, 2
	mov al, __dos_sectors__ ;read 19 sectors
	pusha
.read_disk:
	popa
	pusha
	stc
	int 13h
	jnc short .give_dump
	call reset_floppy
	jnc short .read_disk
	jmp short .err
.give_dump:
	popa
	
	push ax
	mov cx, 512 ;read many bytes from floppy disk
	mov ax, __dos_sectors__ ;the sectors we readed
	mul cx
	mov cx, ax
	pop ax
	
	xor ax, ax
.search_filename:
	xchg cx, dx
	
	mov si, .kernel_filename
	mov cx, 9
	rep cmpsb
	je short .load_file
	
	inc ax ;increment bytes
	inc di
	
	xchg dx, cx
	loop .search_filename
	jmp short .err
.load_file:
	mov si, word [.pointer] ;pointer of data
	mov ax, word [es:si] ;get data
	
	cmp ax, 0ff8h
	jae short .end
	inc word [.pointer] ;incrment one byte in the buffer
	jmp short .load_file
.end:
	pop ax ;ax is ok
	mov dl, [floppy.drive_number] ;give our kernel drive number
	
	jmp __kernel__:__afpfs_default__ ;do the long jump!
	
	.pointer					dw 0
	.sect						dw 0
	
.error:
	mov si, .err
	call print_text
	jmp reboot
	
	.kernel_filename			db 'KERNELSYS'
	.err						db 'kernel.sys was not found',0
	
;=======================================================================
;
;boot.io - io, but is so primitive that micro kernels laugh at it
;
;=======================================================================

logical_to_hts:
	push bx
	push ax
	
	mov bx, ax ;save logical sector
	xor dx, dx
	div word [floppy.sectors_per_track]
	inc dl ;sectors starts at 1
	mov cl, dl ;cl is for sectors
	mov ax, bx
	xor dx, dx ;calculate head
	div word [floppy.sectors_per_track]
	xor dx, dx
	div word [floppy.sides]
	mov dh, dl ;heads/side
	mov ch, al ;track
	
	pop ax ;restore ax and bx
	pop bx
	
	mov dl, byte [floppy.drive_number] ;save device number
	retn
	
reset_floppy:
	push ax
	push dx
	xor ax, ax
	mov dl, byte [floppy.drive_number]
	stc
	int 13h
	pop dx
	pop ax
	retn
	
print_text:
	pusha
	mov ah, 0eh
.loop:
	lodsb ;get byte from string
	test al, al ;is byte null terminator?
	jz .end
	int 10h
	jmp .loop
.end:
	popa ;restore registers
	retn
	
reboot:
	xor ax, ax
	int 16h
	xor ax, ax
	int 19h
	hlt ;halt cpu if reboot didnt worked

times 510-($-$$) db 0
dw 0aa55h

buffer:
