jmp start

jmp enable_A20
jmp enable_A20_PS2
jmp testA20

start:
	ret

enable_A20:
	push ax
	
	call testA20
	
	cmp ax, 1
	je .A20_enabled
.enable_A20_kb:
	call enable_A20_PS2
	
	call testA20
	
	cmp ax, 1
	je .A20_enabled
	
	stc ; Set carry flag
	
	jmp short .end
.A20_enabled:
	clc ; Clear carry flag
.end:
	pop ax
	ret
	
enable_A20_PS2:
	cli
	
	call PS2_wait_send
	mov al, 0ADh
	out 064h, al
	
	call PS2_wait_send
	mov al, 0D0h
	out 064h, al
	
	call PS2_wait_get
	in al, 060h
	
	push ax
	
	call PS2_wait_send
	mov al, 0D1h
	out 064h, al
	
	pop ax
	
	call PS2_wait_send
	or al, 2
	out 060h, al
	
	call PS2_wait_send
	mov al, 0AEh
	out 064h, al
	
	call PS2_wait_send
	sti
	ret

PS2_wait_send:
	in al,0x64
	test al,2
	jnz PS2_wait_send
	ret

PS2_wait_get:
	in al,0x64
	test al,1
	jz PS2_wait_get
	ret

testA20:
	push si ; Save flags and register
	push di
	push ds
	push es
	
	cli
	
	push ax
	mov ah, 0Eh
	mov al, '+'
	int 10h
	pop ax
	
	xor ax, ax ; AX = 0
	mov es, ax ; Lowest segment (0000h)
	
	not ax ; AX = 0FFFFh
	mov ds, ax ; Top segment (64k)
	
	mov di, 0500h
	mov si, 0510h
	
	mov al, byte [es:di]
	push ax
	
	mov al, byte [ds:si]
	push ax
	
	mov byte [es:di], 000h
	mov byte [ds:si], 0FFh
	
	cmp byte [es:di], 0FFh
	
	pop ax
	mov byte [ds:si], al
	
	pop ax
	mov byte [es:di], al
	
	mov ax, 0
	je .end
	
	mov ax, 1
.end:
	pop es
	pop ds
	pop di
	pop si
	ret
