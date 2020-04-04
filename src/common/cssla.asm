[section .text]

;@name:			putc
;@desc:			prints a char
;@param:		word: character
;@return:		n/a
_putc:
	push bp
	mov bp, sp
	
	push si
	push di
	push ax
	push es
	push bx
	
	mov al, [bp+4]
	
	mov ah, [text_attr]
	
	cmp al, 0Dh
	je .newline
	
	cmp al, 0Ah
	je .return
	
	cmp al, 08h
	je .back
	
	push ax
	
	mov ax, [text_seg] ;segmentate
	mov es, ax ;to text location
	
	mov ax, word [text_y] ;see if it is time to scroll
	cmp ax, word [text_h]
	jge .do_scroll
	
	mov ax, [text_w] ;y*w
	mov bx, [text_y]
	mul bx ;result now in ax
	add ax, word [text_x] ;add x to ax
	shl ax, 1
	mov bx, ax
	
	pop ax
	
	mov word [es:bx], ax ;put char with attrib
	
	inc word [text_x]
.end:
	pop bx
	pop es
	pop ax
	pop di
	pop si
	
	pop bp
	ret
.do_scroll:
	pop ax
	
	call scroll
	
	mov ax, [text_h]
	dec ax
	mov word [text_y], ax
	
	jmp short .end

.newline:
	push ax
	mov ax, word [text_y] ;see if it is time to scroll
	cmp ax, word [text_h]
	jge .do_scroll
	pop ax

	inc word [text_y] ;increment y
.return:
	mov word [text_x], 0 ;return to 0
	jmp short .end
.back:
	dec word [text_x] ;decrement char
	jmp short .end

;@name:			print_nibble
;@desc:			print's al's nibble
;@param:		char c
;@return:		ax: trash
_print_nibble:
	push bp
	mov bp, sp

	mov ax, [bp+4]
	xor ah, ah

	push ax
	
	and al, 0Fh
	cmp al, 09h ;if it is higher than 9 use base 16
	jbe short .do_print
	add al, 7 ;add A-F
.do_print:
	add al, '0' ;add 0-9
	
	push ax
	call _putc ;print character
	add sp, 2
	
	pop ax ;restore ax
	
	pop bp
	ret
	
;@name:			print_byte
;@desc:			prints al
;@param:		al: char
;@return:		n/a
_print_byte:
	push bp
	mov bp, sp
	
	push cx
	push ax
	
	mov ax, [bp+4]
	xor ah, ah
	
	mov cl, 4
	shr al, cl
	push ax
	call _print_nibble
	add sp, 2
	pop ax
	
	push ax
	push ax
	call _print_nibble
	add sp, 2
	pop ax
	
	pop cx
	pop bp
	ret
	
;@name:			print_word
;@desc:			prints ax
;@param:		ax: num
;@return:		n/a
_print_word:
	push bp
	mov bp, sp
	
	push ax
	mov ax, [bp+4]
	
	xchg ah, al
	push ax
	call _print_byte
	add sp, 2
	
	xchg ah, al
	push ax
	call _print_byte
	add sp, 2
	
	pop ax
	pop bp
	ret
	
;@name:			clrscr
;@desc:			clears the screen
;@param:		n/a
;@return:		n/a
_clrscr:
	push bp
	mov sp, bp
	
	push ax
	push bx
	push cx
	push es
	push di
	
	mov ax, [text_seg] ;segmentate
	mov es, ax ;to text location
	
	mov bx, [text_w] ;total size of thing
	mov ax, [text_h]
	mul bx
	mov cx, ax ;place in the counter
	
	mov ah, [text_attr]
	mov al, ' '
	xor di, di
.loop:
	mov word [es:di], ax
	
	add di, 2 ;skip a full word
	
	loop .loop
	
	pop di
	pop es
	pop cx
	pop bx
	pop ax
	
	pop bp
	ret

;@name:			update_cursor_to_curr
;@desc:			updates curosr position (text-mode) to current char X,Y
;@param:		n/a
;@return:		n/a
;(Internal-function)
update_cursor_to_curr:
	push ax
	push bx
	push cx
	
	mov bx, [text_w] ;calculate position...
	mov ax, [text_y]
	mul bx
	mov bx, [text_x]
	add ax, bx ;now we have position!
	mov bx, ax ;save ax in bx
	
	mov dx, 03D4h ;03D4h
	mov al, 0Fh
	out dx, al
	
	inc dx ;03D5h
	mov ax, bx
	and ax, 0FFh
	out dx, al
	
	dec dx ;03D4h
	mov al, 0Eh
	out dx, al
	
	inc dx ;03D5h
	mov ax, bx
	mov cl, 8 ;shift by right 8 bits
	shr ax, cl
	and ax, 0FFh
	out dx, al
	
	pop cx
	pop bx
	pop ax
	ret
	
;@name:			scroll
;@desc:			scrolls the screen down
;@param:		n/a
;@return:		n/a
scroll:
	push ax
	
	dec word [text_y] ;decrease y
	dec word [text_y]
	
	mov ax, [text_seg] ;set segments
	mov es, ax ;to text location
	
	mov cx, word [text_w] ;bytes to copy
	mov ax, word [text_h] ;(size of screen - 1 scanline)
	dec ax
	mul cx
	mov cx, ax ;transfer to counter register
	
	xor di, di ;di starts at line 0
	
	mov si, [text_w]
	shl si, 1 ;shift to left to align with word
.move_lines:
	mov ax, word [es:si]
	mov word [es:di], ax
	
	add di, 2
	add si, 2
	
	loop .move_lines
	
	mov di, [text_w] ;position of last scanline
	mov ax, [text_h]
	dec ax
	mul di
	mov di, ax ;transfer to di
	shl di, 1 ;align to word by shifting to left
	
	mov cx, word [text_w]
	
	mov ah, byte [text_attr]
	mov al, ' '
.clear_last: ;clear bottomest line of the text memory
	mov word [es:di], ax
	
	add di, 2
	
	loop .clear_last
	
	pop ax
	ret

[section .text]

text_w			dw 0 ;data
text_h			dw 0
text_x			dw 0 ;positions
text_y			dw 0

text_seg		dw 0 ;segment
text_attr		db 0 ;current text attribute
