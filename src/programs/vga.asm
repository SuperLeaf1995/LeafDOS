use16
cpu 8086
org 8000h

start:
	mov ah, 0Eh
	mov al, 'V'
	int 10h
	ret
