;@name:			dumpregs
;@desc:			prints all registers and debug stuff
;@param:		n/a
;@return:		n/a
_dumpregs:
	push dx
	push cx
	push bx
	push ax
	push di
	push si
	push es
	push ds
	
	mov si, .ds
	call _printf
	pop ax ;ds
	call print_word
	
	mov al, ' '
	call _putc
	mov si, .es
	call _printf
	pop ax ;es
	call print_word
	
	mov si, .nl
	call _printf
	
	mov si, .si
	call _printf
	pop ax ;si
	call print_word
	
	mov al, ' '
	call _putc
	mov si, .di
	call _printf
	pop ax ;di
	call print_word
	
	mov si, .nl
	call _printf
	
	mov si, .ax
	call _printf
	pop ax ;ax
	call print_word
	
	mov al, ' '
	call _putc
	mov si, .bx
	call _printf
	pop ax ;bx
	call print_word
	
	mov al, ' '
	call _putc
	mov si, .cx
	call _printf
	pop ax ;cx
	call print_word
	
	mov al, ' '
	call _putc
	mov si, .dx
	call _printf
	pop ax ;dx
	call print_word
	
	mov si, .nl
	call _printf
	ret
	
.ax			db "AX: ",0
.bx			db "BX: ",0
.cx			db "CX: ",0
.dx			db "DX: ",0
.si			db "SI: ",0
.di			db "DI: ",0
.es			db "ES: ",0
.ds			db "DS: ",0
.nl			db 13,0
