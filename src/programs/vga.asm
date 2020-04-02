use16
cpu 8086
org 32768

start:
	mov ah, 0Eh
	mov al, 'V'
	int 10h
	ret
