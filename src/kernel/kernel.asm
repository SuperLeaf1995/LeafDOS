use16
cpu 8086
org 0

kernel				equ 0500h
buffer				equ	0800h
autorun				equ 0F00h

program				equ 2000h

start:
	xor ax, ax
	cli ; Set our stack
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh
	sti
	cld ; Go up in RAM
	mov ax, kernel ; Segmentate to
	mov es, ax ; all data and extended segment into the
	mov ds, ax ; kernel segment
