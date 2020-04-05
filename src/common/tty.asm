use16
cpu 8086
org 1000h

kernel				equ 0500h
buffer				equ	0800h

start:
	mov si, greet
	
	lodsb
	push ax
	call _putc
	add sp, 2
	
	ret
	
greet		db "Hello world!",0Dh,0

; @name:			putc
; @desc:			prints a char
; @param:			WORD char
; @return:			n/a
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
	
	call _scrup
	
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
	
; @name:			scrup
; @desc:			scrolls the screen down
; @param:			n/a
; @return:			n/a
_scrup:
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
	
; @name:			clrscr
; @desc:			clears the screen
; @param:			n/a
; @return:			n/a
_clrscr:
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
	ret

; @name:			pnibble
; @desc:			prints a nibble
; @param:			WORD char
; @return:			n/a
_pnibble:
	push bp
	mov bp, sp
	
	mov ax, [bp+4]

	and al, 0Fh
	cmp al, 09h ;if it is higher than 9 use base 16
	jbe short .do_print
	add al, 7 ;add A-F
.do_print:
	add al, '0' ;add 0-9
	
	push ax
	call _putc ;print character
	add sp, 2
	
	pop bp
	ret
	
; @name:			pbyte
; @desc:			prints a byte in hex
; @param:			WORD char
; @return:			n/a
_pbyte:
	push bp
	mov bp, sp
	
	mov ax, [bp+4]

	push cx
	
	push ax
	mov cl, 4
	shr al, cl
	xor ah, ah
	push ax
	call _pnibble
	add sp, 2
	pop ax
	
	push ax
	xor ah, ah
	push ax
	call _pnibble
	add sp, 2
	pop ax
	
	pop cx
	
	pop bp
	ret
	
; @name:			pword
; @desc:			prints a word in hex
; @param:			WORD num
; @return:			n/a
_pword:
	push bp
	mov bp, sp
	
	mov ax, [bp+4]

	push ax
	
	xchg ah, al
	
	push ax
	call _pbyte
	add sp, 2
	
	xchg ah, al
	
	push ax
	call _pbyte
	add sp, 2
	
	pop ax
	
	pop bp
	ret

; @name:			updcur
; @desc:			updates curosr position (text-mode) to current char X,Y
; @param:			n/a
; @return:			n/a
_updcur:
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

text_w			dw 0 ;data
text_h			dw 0
text_x			dw 0 ;positions
text_y			dw 0

text_seg		dw 0 ;segment
text_attr		db 0 ;current text attribute
