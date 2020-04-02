;@name:			putc
;@desc:			prints a char
;@param:		al: character
;@return:		n/a
_putc:
	push si
	push di
	push ax
	push es
	push bx
	
	mov ah, [text_attr]
	
	cmp al, 0Dh
	je .newline
	
	cmp al, 0Ah
	je .return
	
	cmp al, 08h
	je .back
	
	push ax
	
	mov ax, [text_y] ;see if it is time to scroll
	cmp ax, [text_h]
	jge .do_scroll
	
	mov ax, [text_seg] ;segmentate
	mov es, ax ;to text location
	
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
	ret
	
.do_scroll:
	;get screen size
	mov cx, 4000
	mov si, word [text_w] ;copy second line first char
	shl si, 1
	
	xor di, di	;to first line first char
				;and then second char and so on...
	
	call _memcpy
	
	dec word [text_y] ;decrement y
	jmp short .return
.newline:
	inc word [text_y] ;increment y
.return:
	mov word [text_x], 0 ;return to 0
	jmp short .end
.back:
	dec word [text_x]
	jmp short .end

;@name:			printf
;@desc:			prints a string (parses stuff)
;@param:		si: string address, stack: va_list
;@return:		n/a
_printf:
	pop bx ;assign bx the return address
.loop:
	lodsb
	
	test al, al ;is character zero?
	jz short .end ;yes, end
	
	cmp al, '%' ;lets check for format...
	je short .check_format

	call _putc

	jmp short .loop
.check_format:
	lodsb ;get next char

	test al, al ;if it is null inmediately end
	jz short .end

	cmp al, 'c' ;char
	je short .format_char
	
	cmp al, 's' ;string set
	je short .format_string
	
	cmp al, 'x' ;unsigned int (hex)
	je short .format_unsigned_int_hex
	
	jmp short .loop
	
;print a char if %c present
.format_char:
	pop ax ;pop char from the va_list (char is a word)
	call _putc
	jmp short .loop
	
;print an string if %s is present
.format_string:
	pop si
.string_loop:
	lodsb
	
	test al, al
	jz short .end_string_loop ;if char is not null continue

	call _putc ;put string's char

	jmp short .string_loop
.end_string_loop:
	jmp short .loop ;return back to main loop
	
;print an unsigned int in hexadecimal if %x is present
.format_unsigned_int_hex:
	pop ax ;get int
	call print_word ;print word
	jmp short .loop
.end:
	push bx ;bx had our return address
	ret ;ret popf off the return address
	
;@name:			gets
;@desc:			scans for whole string
;@param:		di: kbuf, bx: max char
;@return:		n/a
_gets:
	push di
	push cx
	push bx
	push ax
	xor cx, cx
.loop:
	cmp cx, 0
	jb short .end
	cmp cx, bx
	jge short .end

	xor ax, ax ;bios interrupts
	mov ah, 10h
	int 16h
	
	cmp al, 0Dh
	je short .end
	
	cmp al, 08h
	je short .back
	
	call _putc
	
	;now key is in al and ah (only al matters)
	stosb ;place it in tempbuf
	
	inc cx
	
	jmp short .loop
.back:
	mov byte [di], 0
	dec di
	
	mov al, 08h
	call _putc
	mov al, ' '
	call _putc
	mov al, 08h
	call _putc
	
	dec cx
	jmp short .loop
.end:
	xor al, al
	stosb ;place a null terminator
	pop ax
	pop bx
	pop cx
	pop di
	ret

;@name:			memcpy
;@desc:			copies memory SI to DI
;@param:		si: src, di: dest, cx: len
;@return:		n/a
_memcpy:
	push cx
	push di
	push si
	push ax
.loop:
	mov al, byte [si]
	mov byte [di], al
	
	loop .loop
.end:
	pop ax
	pop si
	pop di
	pop cx
	ret

;@name:			memcmp
;@desc:			compares memory SI and DI
;@param:		si: str1, di: str2, cx: len
;@return:		cf: set if equal
_memcmp:
	push cx
	push di
	push si
	push ax
	test cx, cx
	jz short .end
.loop:
	mov al, byte [si] ;get bytes
	mov ah, byte [di]
	
	cmp al, ah
	jnz short .not_equ
	
	inc di ;increment stuff
	inc si
	loop .loop ;once all bytes scaned go to equ
.equ:
	stc
	jmp short .end
.not_equ:
	clc
.end:
	pop ax
	pop si
	pop di
	pop cx
	ret
	
;@name:			strcmp
;@desc:			compares string SI and DI
;@param:		si: str1, di: str2
;@return:		cf: set if equal
_strcmp:
	push cx
	push di
	push si
	push ax
	test cx, cx
	jz short .end
.loop:
	mov al, byte [si] ;get bytes
	mov ah, byte [di]
	
	cmp al, ah
	jnz short .not_equ
	
	test al, al
	jz short .check_if_null
	
	inc di ;increment stuff
	inc si
	loop .loop ;once all bytes scaned go to equ
.check_if_null:
	test ah, ah
	jnz short .not_equ
.equ:
	stc
	jmp short .end
.not_equ:
	clc
.end:
	pop ax
	pop si
	pop di
	pop cx
	ret

;@name:			_strup
;@desc:			converts a string to all-uppercase
;@param:		si: string
;@return:		n/a
_strup:
	push si
	push ax
.loop:
	mov al, byte [si]
	inc si
	
	test al, al ;null terminator
	jz short .end

	cmp al, 'a';is it betwen a-z?
	jnge short .loop
	cmp al, 'z'
	jnle short .loop
	
	sub al, 32 ;convert lowercase into uppercase
	
	mov byte [si-1], al
	
	jmp short .loop
.end:
	pop ax
	pop si
	ret
	
;@name:			_strcpyup
;@desc:			converts a string to all-uppercase and copies it into DI
;@param:		si: string, di: output string
;@return:		n/a
_strcpyup:
	push si
	push di
	push ax
.loop:
	lodsb ;get char from string
	
	test al, al ;null terminator
	jz short .end

	cmp al, 'a'
	jnge short .loop
	cmp al, 'z' ;is it betwen a-z?
	jnle short .loop ;yes, do a-z
	
	sub al, 32 ;convert lowercase into uppercase
	
	stosb ;place uppered (or not) char in out string
	
	jmp short .loop
.end:
	pop ax
	pop di
	pop si
	ret

;@name:			_toupper
;@desc:			converts all lowercase into uppercase
;@param:		al: char
;@return:		al: upper char
_toupper:
	cmp al, 'a'
	jnge short .end
	cmp al, 'z' ;is it betwen a-z?
	jnle short .end ;yes, do a-z
	sub al, 32 ;convert lowercase into uppercase
.end:
	ret
	
;@name:			print_nibble
;@desc:			print's al's nibble
;@param:		al: char
;@return:		ax: trashed
print_nibble:
	and al, 0Fh
	cmp al, 09h ;if it is higher than 9 use base 16
	jbe short .do_print
	add al, 7 ;add A-F
.do_print:
	add al, '0' ;add 0-9
	call _putc ;print character
	ret
	
;@name:			print_byte
;@desc:			prints al
;@param:		al: char
;@return:		n/a
print_byte:
	push cx
	push ax
	mov cl, 4
	shr al, cl
	call print_nibble
	pop ax
	push ax
	call print_nibble
	pop ax
	pop cx
	ret
	
;@name:			print_word
;@desc:			prints ax
;@param:		ax: num
;@return:		n/a
print_word:
	push ax
	xchg ah, al
	call print_byte
	xchg ah, al
	call print_byte
	pop ax
	ret
	
text_w		dw 0 ;data
text_h		dw 0
text_x		dw 0 ;positions
text_y		dw 0

text_seg	dw 0 ;segment
text_attr	db 0 ;current text attribute
