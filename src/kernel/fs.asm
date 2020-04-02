;@name:			read_sector
;@desc:			reads a sector
;@param:		L2HTS, al: sect. to read, es:bx palce to put data
;@return:		cf: set on error
read_sector:
	push ax
	mov ah, 2
	
	push ax
	push bx
	push cx
	push dx
.loop:
	pop dx
	pop cx
	pop bx
	pop ax
	
	push ax
	push bx
	push cx
	push dx
	
	stc
	int 13h
	jnc short .end
	call reset_drive
	jnc short .loop
	jmp short .error
.end:
	pop dx
	pop cx
	pop bx
	pop ax
	
	pop ax
	clc
	ret
.error:
	pop dx
	pop cx
	pop bx
	pop ax
	
	pop ax
	stc
	ret

;@name:			reset_drive
;@desc:			resets drive
;@param:		device_number: current working drive
;@return:		n/a
reset_drive:
	push ax
	push dx
	xor ax, ax
	mov dl, byte [device_number]
	stc
	int 13h
	pop dx
	pop ax
	ret

;@name:			logical_to_hts
;@desc:			converts logical sector to HTS
;@param:		ax: logical sector
;@return:		int 13h params
logical_to_hts:
	push bx
	push ax
	mov bx, ax
	xor dx, dx
	div word [sectors_per_track]
	add dl, 01h
	mov cl, dl
	mov ax, bx
	xor dx, dx
	div word [sectors_per_track]
	xor dx, dx
	div word [sides]
	mov dh, dl
	mov ch, al
	pop ax
	pop bx
	mov dl, byte [device_number]
	ret
