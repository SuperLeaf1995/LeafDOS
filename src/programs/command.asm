use16
cpu 8086
org 0B00h

start:
	mov ah, 0Eh
	mov al, '.'
	int 10h
	jmp start
