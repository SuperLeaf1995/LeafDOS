use16
cpu 8086
org 19020

%include "src/common/ssla.inc"

start:
	mov ah, 0Eh
.re:
	mov al, 20h
	xor cx, cx
.loss:
	int 10h
	
	cmp al, 255
	je short .re
	
	inc al
	
	jmp short .loss
