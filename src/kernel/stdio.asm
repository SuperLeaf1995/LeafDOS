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
	ret
	
.do_scroll:
	pop ax
	
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
	dec word [text_x]
	
	jmp short .end
	
;@name:			clrscr
;@desc:			clears the screen
;@param:		n/a
;@return:		n/a
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
	call update_cursor_to_curr ;set the text cursor thing
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
	
	call _putc ;display inputted character
	call update_cursor_to_curr ;update the cursor
	
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
	
_kbhit:
	xor ax, ax ;is key pressed?
	inc ah
	int 16h
	
	jz .no_key
	
	xor ax, ax ;get the key if pressed
	int 16h
	
	ret ;ax now has the key
.no_key:
	xor ax, ax
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
	
	inc di
	inc si
	
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
	
;@name:			_fopen
;@desc:			opens a file
;@param:		si: filename, ax: segment/address to load on
;@return:		n/a
_fopen:
	push ax
	push bx
	push cx
	push si
	push di
	
	mov word [.segment], ax
	mov word [.filename], si
	
	call reset_drive
	jc .error

	mov ax, 19 ;read from root directory
	call logical_to_hts ;get parameters for int 13h
	
	mov si, SEG_BUFFER ;sectors of the
	mov bx, si ;root directory
	
	mov al, 14 ;read 14 sectors
	call read_sector
	jc .error
	
	mov cx, word [root_dir_entries]
	mov bx, -32
.find_root_entry:
	add bx, 32
	mov di, SEG_BUFFER
	add di, bx
	
	xchg dx, cx

	mov cx, 11 ;compare filename with entry
	mov si, [.filename]
	rep cmpsb
	je short .file_found
	
	xchg dx, cx
	loop .find_root_entry ;loop...
	jmp .error ;file not found
.file_found:
	mov ax, word [es:di+0Fh] ;get cluster
	mov word [.cluster], ax
	
	mov ax, 1
	call logical_to_hts
	
	mov di, SEG_BUFFER
	mov bx, di
	
	mov al, 9 ;read all sectors of the FAT
	call read_sector
	jc .error
	
	mov bx, word [.segment]
	
	mov al, 1
	mov ah, 2
	
	push ax
.load_sector:
	mov ax, word [.cluster]
	add ax, 31
	call logical_to_hts
	
	mov bx, word [.segment]
	
	pop ax
	push ax
	
	stc
	int 13h
	
	jnc short .next_cluster
	call reset_drive
	jmp short .load_sector
.next_cluster:
	mov ax, [.cluster]
	xor dx, dx
	mov bx, 3
	mul bx
	mov bx, 2
	div bx
	
	mov si, SEG_BUFFER
	add si, ax
	
	mov ax, word [ds:si] ;get cluster word...
	
	or dx, dx ;is our cluster even or odd?
	jz short .even_cluster
.odd_cluster:
	push cx
	mov cl, 4
	shr ax, cl ;shift 4 bits ax
	pop cx
	jmp short .check_eof
.even_cluster:
	and ax, 0FFFh
.check_eof:
	mov word [.cluster], ax ;put cluster in cluster
	cmp ax, 0FF8h ;check for eof
	jae short .end
	
	push ax
	mov ax, [bytes_per_sector]
	add word [.segment], ax ;bytes
	pop ax
	jmp short .load_sector
.end: ;file is now loaded in the ram
	pop ax ;pop off ax
	
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	clc
	ret
.error:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	stc
	ret

.filename			dw 0
.segment			dw 0
.cluster			dw 0
.pointer			dw 0

;@name:			_flist
;@desc:			returns entire fat entries
;@param:		di: output place to put entries
;@return:		n/a
_flist:
	push ax
	push bx
	push cx
	push si
	push di
	
	call reset_drive
	jc .error

	mov ax, 19 ;read from root directory
	call logical_to_hts ;get parameters for int 13h
	
	mov si, SEG_BUFFER ;sectors of the
	mov bx, si ;root directory
	
	mov al, 14 ;read 14 sectors
	call read_sector
	jc .error
	
	mov cx, word [root_dir_entries]
	mov bx, -32
.find_root_entry:
	add bx, 32
	mov di, SEG_BUFFER
	add di, bx
	
	pop si
	push di
	xchg di, si
	mov cx, 32 ;write the entire entry there
	rep stosb
	pop di
	push si
		
	loop .find_root_entry ;loop...
.end:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	clc
	ret
	
.error:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	stc
	ret

.cluster			dw 0
.pointer			dw 0
	
;@name:			strfat12
;@desc:			converts a string to FAT12 compatible filename
;@param:		si: string, di: output string
;@return:		n/a
_strfat12:
	push di
	push si
	push ax
	push cx
	push bx

	call _strup

	;copy file name until a . is found
	mov cx, 8 ;name is 8 chars lenght (+ dot)
.copy_name:
	lodsb
	
	test al, al
	jz short .implicit_exe ;pad the name, and add a EXE extension
	
	cmp al, '.'
	je short .found_dot
	
	stosb
	loop .copy_name
	
	;find the . in the filename, chomp last 2 bytes with ~1
.find_dot_chomp:
	jmp .search_dot
	
	;dot found, pad with whitespaces
.found_dot:
	test cx, cx ;do not proced if cx is 0, this causes an
	jz short .check_extension ;infinite loop!
	mov al, ' ' ;place whitespaces
.pad_name:
	stosb
	loop .pad_name
.check_extension:
	mov cx, 3 ;extension is 3 bytes
.copy_extension:
	lodsb
	
	test al, al
	jz short .pad_extension_check
	
	stosb
	loop .copy_extension
	;loop finished, nothing else to add...
	jmp short .end
.pad_extension_check:
	test cx, cx ;not proced if cx is zero
	jz short .end
	mov al, ' '
.pad_extension:
	stosb
	loop .pad_extension
.end:
	xor al, al
	stosb
	
	pop bx
	pop cx
	pop ax
	pop si
	pop di
	ret
	
.implicit_exe_chomp:
	sub di, 2 ;go back 2 bytes
	mov al, '~'
	stosb ;place the ~ thing
	mov al, '1'
	stosb ;place the number
.implicit_exe:
	test cx, cx ;do not proced if cx is 0, this causes an
	jz short .add_exe_ext ;infinite loop!
	mov al, ' ' ;place whitespaces
.pad_name_exe:
	stosb
	loop .pad_name_exe
.add_exe_ext:
	mov al, 'P'
	stosb
	mov al, 'R'
	stosb
	mov al, 'G'
	stosb
	jmp short .end

.search_dot:
	;trash out everything after ~1 and the .
	;check if next byte (byte 9) is a dot
	lodsb
	cmp al, '.'
	je .found_dot
.loop_dot:
	lodsb
	
	test al, al
	jz short .implicit_exe_chomp
	
	cmp al, '.'
	je short .find_dot_and_chomp
	
	jmp short .loop_dot
.find_dot_and_chomp: ;chomp some 2 bytes
	sub di, 2 ;go back 2 bytes
	mov al, '~'
	stosb ;place the ~ thing
	mov al, '1'
	stosb ;place the number
	jmp .found_dot
	
.tmpbuf		times 64 db 0
	
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

;@name:			update_cursor_to_curr
;@desc:			updates curosr position (text-mode) to current char X,Y
;@param:		n/a
;@return:		n/a
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
	
text_w		dw 0 ;data
text_h		dw 0
text_x		dw 0 ;positions
text_y		dw 0

text_seg	dw 0 ;segment
text_attr	db 0 ;current text attribute
