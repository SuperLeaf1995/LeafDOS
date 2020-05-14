use16
cpu 8086
org 0C00h

start:
	mov ah, 0Eh
	mov al, 'B'
	int 10h
	jmp start
