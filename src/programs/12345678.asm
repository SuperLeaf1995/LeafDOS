use16
org 0

start:
	mov si, msg
	call 0006h

	mov ax, 1
	ret

msg db '12345678!!! Yay!',0x0D,0x0A,0x00
