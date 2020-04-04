use16
cpu 8086
org 4F00h

[section .text]

start:
	mov ah, 0Eh
	mov al, 'a'
	int 10h
	jmp $
