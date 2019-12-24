;=======================================================================
;
;io.lib / io.asm
;
;io (input-output) library is the in built library of the kernel, this
;library is part of ldos's kernel, manages everything from keyboard
;to display, and even the serial ports.
;
;it also feeds the programs with functions they can use, for example
;io_display_print_text.
;
;the format for each function name is the follows:
;
;io + group + name
;
;=======================================================================
	
;in = ax: logical sector
;out = cl: sector, dh: head, ch: track, dl: drive
io_disk_logical_to_hts:
	push bx
	push ax
	
	mov bx, ax ;save logical sector
	
	xor dx, dx
	div word [disk_sectors_per_track]
	inc dl ;sectors are nonzero
	mov cl, dl ;cl is for sectors
	
	mov ax, bx
	xor dx, dx ;calculate head
	div word [disk_sectors_per_track]
	
	xor dx, dx
	div word [disk_sides]
	mov dh, dl ;heads/side
	mov ch, al ;track
	
	pop ax ;restore ax and bx
	pop bx
	
	mov dl, byte [disk_drive_number] ;save device number
	ret
	
;in = si: filename, ax: segment to load file to
;out = cf: clear if sucess
io_disk_read_file:
	moV word [.filename], si
	moV word [.segment], ax
	moV ax, 1
	call io_disk_logical_to_hts
	moV si, __buffer__
	moV bx, ds
	moV es, bx
	moV bx, si
	moV ah, 2
	moV al, 24 ;read all sectors
	pusha
.read_disk:
	popa
	pusha
	stc
	int 13h
	jnc .prepare_buffer
	call io_disk_reset ;error on disk?
	jnc .read_disk
	;error
	stc
	ret
.prepare_buffer:
	popa
	pusha
	moV ax, ds ;now it points to our buffer
	moV es, ax
	moV di, __buffer__
	xor ax, ax
	moV word [.sect], ax ;sector is zero, for now
.find_filename:
	add word [.sect], 1 ;add one sector per loop
	moV cx, 512 ;read sector per sector
.loop:
	xchg cx, dx
	moV si, data_program_to_load
	moV cx, 9
	rep cmpsb
	je short .found_file
	add ax, 1
	moV di, __buffer__
	add di, ax
	xchg dx, cx
	loop .loop
	cmp word [.sect], 16 ;more than total sectors!
	jge .not_found
	jmp .find_filename ;another sector...
.found_file:
	moV ax, word [.segment] ;make es:bx to point to our load place
	moV es, ax
	moV bx, 0

	moV ax, word [.sect] ;sector where file is
	call io_disk_logical_to_hts
	
	moV ah, 2 ;read from the cluster we found the filename
	moV al, 18
	
	stc
	int 13h
	jnc .end
	call io_disk_reset ;if there is error, reset floppY
	jmp .found_file
.end:
	popa
	clc
	ret
	
.not_found:
	popa
	stc
	ret
	
	.ptr						dw 0
	.sect						dw 0
	.filename					dw 0
	.segment					dw 0
	
io_disk_reset:
	push ax
	push dx
	
	xor ax, ax
	mov dl, byte [disk_drive_number]
	stc
	int 13h
	
	pop dx
	pop ax
	ret
	
;=======================================================================
;
;io.display - video and display routines, anything graphical
;
;=======================================================================
	
;in = ah: color, al: character
;out = n/a
io_display_clear_text_screen:
	pusha
	push es
	
	mov cx, ax ;save stuff in ax

	mov ax, word [data_text_memory]
	mov es, ax
	xor di, di

	mov ax, [data_text_mode_tall]
	mov bx, [data_text_mode_wide]
	mul bx
	shl ax, 1
	
.loop:
	cmp di, ax
	je .end
	
	mov word [es:di], cx ;repeat...
	
	inc di ;advance by a word
	inc di
	
	jmp .loop
.end:
	pop es
	popa
	ret
	
;in = al: starting scanline, ah: ending scanline
;out = n/a
io_display_enable_text_mode_cursor:
	push ax
	push dx
	
	mov byte [.data_end], ah
	mov byte [.data_start], al
	
	mov dx, 03d4h
	
	mov al, 0ah
	;put starting scanline
	out dx, al ;send 0a byte
	inc dx
	in al, dx ;get byte
	and al, 0c0h
	or al, [.data_start]
	out dx, al
	;put ending scanline
	dec dx
	mov al, 0bh
	out dx, al ;send 0e byte
	mov dx, 03e0h
	in al, dx ;get byte
	and al, 0e0h
	or al, [.data_end]
	mov dx, 03d5h
	out dx, al
	
	pop dx
	pop ax
	ret
	
	.data_end		db 0
	.data_start	db 0
	
;in = n/a
;out = n/a (and no more blinky :( )
io_display_disable_text_mode_cursor:
	pusha
	
	mov dx, 03d4h ;send to vga register that we dont want cursor
	mov al, 0ah
	out dx, al
	
	inc dx
	mov al, 020h
	out dx, al
	
	popa
	ret
	
;in = al: chatacter
;out = n/a
io_display_print_char:
	pusha
	push es
	
	mov byte [.data_character], al
	
	;point to text memory
	mov ax, word [data_text_memory]
	mov es, ax
	
	mov ah, 1bh
	
	mov cx, ax ;save ax in cx
	
	movzx ax, byte [data_text_y] ;y to ax
	movzx dx, byte [data_text_mode_wide]
	mul dx
	shl ax, 1
	
	movzx bx, byte [data_text_x] ;x to bx
	shl bx, 1 ;skip attribute
	
	xor di, di 	;di points at start of memory
	add di, bx 	;x plus
	add di, ax 	;y equals
				;current character location
	
	mov ax, cx
	mov al, byte [.data_character]
	
	cmp al, 08h
	je short .backspace
	
	cmp al, __newline__
	je short .newline
	
	cmp di, 4000
	jae short .scroll

	stosw ;place it in the video memory
	
	inc byte [data_text_x] ;finaly increment x by one
	jmp short .end ;warp to the end
.backspace:
	mov al, byte [data_text_x];is this the first character
	test al, al					;of the line?
	jz short .backspace_y	;then decrement y, and warp x
.backspace_x:
	dec byte [data_text_x] ;or just decrement x
	jmp short .end
.backspace_y:
	dec byte [data_text_y] ;decrement y
	mov al, byte [data_text_mode_wide]
	mov byte [data_text_x], al ;warp x to 80 (max chars in line no.)
	jmp short .end
.scroll:
	stosw ;place character before scrolling
	call io_display_scroll_down
	inc byte [data_text_x]
	jmp short .end
.newline:
	inc byte [data_text_y]
	mov byte [data_text_x], 0
	jmp short .end
.end:
	pop es
	popa
	ret
	
	.data_character	db 0
	
;in = si: string
;out = n/a
io_display_print_text:
	push ax
.loop:
	lodsb
	
	test al, al
	jz .end
	
	call io_display_print_char
	jmp .loop
.end:
	pop ax
	ret
	
;in = n/a
;out = n/a
io_display_scroll_down:
	pusha
	push es
	
	;copy line 1 to line 0, line 2 to line 1 and so on
	mov ax, word [data_text_memory]
	mov es, ax
	
	;destination is to the first line
	xor di, di
	
	;source is the line below
	;movzx ax, byte [data_text_mode_tall]
	;movzx bx, byte [data_text_mode_wide]
	;mul bx
	;xchg bx, ax ;bx now holds ax
	
	movzx si, byte [data_text_mode_wide]
	shl si, 1
	
.loop:
	mov ax, word [es:si] ;get word below
	mov word [es:di], ax ;place the word in dest.
	
	cmp bx, 2000
	jae .end
	
	inc bx
	
	inc si
	inc si
	
	inc di
	inc di
	
	jmp .loop
.end:
	
	mov al, byte [data_text_mode_tall] ;tall-1 = new position
	dec al
	mov byte [data_text_y], al
	mov byte [data_text_x], 0
	
	pop es
	popa
	ret
	
;in = bl: cursor x, bh: cursor y
;out = n/a
io_display_update_text_mode_cursor:
	pusha
	
	mov ax, [data_text_mode_wide]
	mul bh ;y*vga_wide+x = cursor position
	xor bh, bh ;delete bh, so we can add bx to ax
	add ax, bx
	
	mov cx, ax ;save ax in cx
	
	mov dx, 03d4h ;send first byte..
	mov al, 0fh ;low port
	out dx, al
	
	mov dx, 03d5h ;low position
	mov ax, cx
	and ax, 0ffh
	out dx, al
	
	mov dx, 03d4h ;high port
	mov al, 0eh
	out dx, al
	
	mov dx, 03d5h ;high position
	mov ax, cx
	shr ax, 8
	and ax, 0ffh
	out dx, al
	
	popa ;we are done, now we restore registers
	ret
	
;=======================================================================
;
;io.keyboard - input/user input stuff
;
;=======================================================================
	
;in = ch: number of chars to read, di: buffer
;out = di: string
io_keyboard_input:
	pusha
	xor cl, cl
.loop:
	call io_keyboard_keypress
	
	push bx
	mov bl, byte [data_text_x]
	mov bh, byte [data_text_y]
	call io_display_update_text_mode_cursor
	pop bx
	
	cmp al, 10 ;newline (enter)
	je .end
	cmp al, 13
	je .end
	cmp al, 8 ;backspace
	je .back
	cmp cl, ch ;did we inputed more chars than the ones we should?
	jge .end
.print_part:
	call io_display_print_char
	inc cl
	stosb
	jmp .loop
.back:
	cmp cl, 0 ;remove character from string
	je .loop ;keep cursor from choking
	dec di
	mov byte [di], 0
	dec cl
	
	mov al, 8 ;retroceed one character
	call io_display_print_char
	mov al, ' ' ;display a space
	call io_display_print_char
	mov al, 8 ;when we displayed a space we advanced a character, go and retroceed again...
	call io_display_print_char
	
	push bx
	mov bl, byte [data_text_x]
	mov bh, byte [data_text_y]
	call io_display_update_text_mode_cursor ;update cursor, so it dosent chokes
	pop bx
	jmp .loop
.end:
	xor al, al
	stosb
	popa
	ret
	
;in = n/a
;out = al: character pressed
io_keyboard_keypress:
	xor ax, ax
	int 16h
	ret
	
;=======================================================================
;
;io.serial - in-built serial driver routines
;
;=======================================================================
	
;in = dx: port number
;out = n/a
io_serial_enable:
	push ax
	push dx
	
	add dx, 1
	xor al, al
	out dx, al ;disable all interrupts
	
	add dx, 2
	mov al, 80h
	out dx, al ;enable dlab
	
	sub dx, 3
	mov al, 02h
	out dx, al ;set divisor
	
	inc dx
	xor al, al
	out dx, al ;set baud rate to somewhere betwen 3800
	
	add dx, 2
	mov al, 03h
	out dx, al ;8 bits and no partity, one stop bit
	
	dec dx
	mov al, 0c7h
	out dx, al ;enable fifo
	
	add dx, 2
	mov al, 0bh
	out dx, al ;irq enabled and dsr set
	
	pop dx
	pop ax
	ret
	
;in = dx: port address
;out = al: byte
io_serial_get_byte:
	push dx
.loop:
	add dx, 5
	in al, dx ;put stuff got from dx to al
	and al, 1
	jz .loop
	
	sub dx, 5
	
	in al, dx
	pop dx
	ret
	
;in = n/a
;out = al: number of serial ports
io_serial_ports_check:
	push es
	push si
	push bx
	push ax
	
	mov ax, 0040h
	mov es, ax
	mov bx, 0
	
	mov ax, word [es:bx] ;get first serial port
	test ax, ax
	jz near .no_first_serial_port ;nope
	;we have serial ports!
.yes_first_serial_port:
	mov bx, 2
	
	mov ax, word [es:bx] ;get second serial port
	test ax, ax
	jz near .no_second_serial_port ;no
.yes_second_serial_port:
	mov bx, 4
	
	mov ax, word [es:bx] ;get third serial port
	test ax, ax
	jz near .no_third_serial_port ;ok, no 3rd port
.yes_third_serial_port:
	mov bx, 6
	
	mov ax, word [es:bx] ;get fourth serial port
	test ax, ax
	jz near .no_third_serial_port ;oh, almost all ports
	mov byte [.data_ports], 4 ;all ports!
.end:
	pop ax
	pop bx
	pop si
	pop es ;segment restored!
	mov al, byte [.data_ports]
	ret
	
.no_first_serial_port:
	mov byte [.data_ports], 0 ;zero ports, if there is no registry here
	jmp near .end
.no_second_serial_port:
	mov byte [.data_ports], 1 ;only one port
	jmp near .end
.no_third_serial_port:
	mov byte [.data_ports], 2 ;only two ports
	jmp near .end
.no_fourth_serial_port:
	mov byte [.data_ports], 3 ;only three ports
	jmp near .end
	
	.data_ports	db 0

;in = dx: port address, al: byte to send
;out = n/a
io_serial_send_byte:
	push ax
	push dx
	
	mov ah, al
.loop:
	add dx, 5
	in al, dx
	test al, 020h ;is serial free for transmiting?
	jz short .loop ;nope
	;ok, lets put it if its empty
	sub dx, 5
	mov al, ah
	out dx, al

	pop dx
	pop ax
	ret
	
;in = dx: port address, si: memory location, cx: how many
;out = n/a
io_serial_send_bytes:
	pusha
.loop:
	cmp cx, 0 ;if counter is zero, end
	je short .end
	
	mov al, byte [si]
	call io_serial_send_byte
	
	inc si ;next byte...
	dec cx
	jmp short .loop
.end:
	popa
	ret
	
;in = dx: port address, si: memory location, cl: how many
;out = cf: clear if sucess
io_serial_ldstp_send_bytes:
	pusha
	;send byte of "incoming data"
	mov al, 017h
	call io_serial_send_byte
	
	call io_serial_get_byte ;get reply...
	cmp al, 01ah ;computer is stupid and didnt understood
	jne short .error
	
	;else if computer 2 understood...
	mov al, 019h ;send byte of "size of packet"
	call io_serial_send_byte
	
	call io_serial_get_byte ;get reply...
	cmp al, 01bh ;how many the odds?
	jne short .error
	
	;at this point, we will send a unsigned byte dicating the size of
	;our packet
	mov al, cl ;put size in al
	call io_serial_send_byte
	
	call io_serial_get_byte
	cmp al, 01ah
	jne short .error
	
	;now its time to send the actual data
	popa ;registers where oofed while we did this initialization
	pusha
.loop:
	cmp cx, 0 ;if counter is zero, end
	je short .end
	
	lodsb ;get byte and send it
	call io_serial_send_byte
	
	dec cx
	jmp short .loop
.end:
	mov al, 01ah ;lets make sure computer finished analyzing data...
	call io_serial_send_byte
	
	call io_serial_get_byte ;get reply...
	
	cmp al, 0bbh ;error, data trown or destroyed
	je .error
	
	popa
	
	clc
	ret
	
.error:
	popa
	stc
	ret
	
;in = dx: port address, di: place to put data, cl: data size limit
;out = cf: clear if sucess, ch: data sent
io_serial_ldstp_get_bytes:
	pusha
	;now we are at the other part of the table
	call io_serial_get_byte ;get "data incoming" byte
	cmp al, 017h
	jne short .abort
	
	mov al, 01ah ;send reply of "ok" byte
	call io_serial_send_byte
	
	call io_serial_get_byte
	cmp al, 019h ;get "size of packet" byte
	jne short .abort
	
	mov al, 01bh ;send reply of "ok gimme data naw"
	call io_serial_send_byte
	
	call io_serial_get_byte ;get size of packet to be sent
	
	;hmm is this bigger than the buffer we allow!?
	cmp cl, al
	jl short .abort
	
	mov ch, al ;store size in ch, for future use
	
	;nope, proceed
	;send reply byte "ok i got ur stuff, now gimme me actual data naw"
	mov al, 01ah
	call io_serial_send_byte
	popa
	pusha
	xor cl, cl ;set cl to zero
.get_bytes:
	cmp cl, ch
	je short .abort
	
	lodsb
	call io_serial_send_byte
	
	inc cl ;decrement counter...
	
	jmp short .get_bytes
	
.end:
	;when we finished receiving data, now we must send the "ok, finish"
	;byte
	call io_serial_get_byte
	
	cmp al, 01ah
	jne .abort
	
	mov al, 0bbh
	call io_serial_send_byte ;done
	popa ;we finished!
	clc
	ret
	
.abort:
	mov al, 0feh ;send error byte (auto cancels everything)
	call io_serial_send_byte
	
	popa
	stc
	ret
	
;=======================================================================
;
;io.memory - memory allocation and management routines
;
;=======================================================================

;in = si: source, di: destination, cx: bytes to copy
;out = n/a
io_memory_copy:
	pusha
.loop:
	cmp cx, 0 ;did we ended yet?
	je .end
	mov al, byte [si]
	mov byte [di], al
	
	inc di
	inc si
	dec cx
	jmp .loop
.end:
	popa
	ret

;in = al: byte to copy, di: destination, cx: times to copy char
;out = n/a
io_memory_copy_byte:
	pusha
.loop:
	cmp cx, 0 ;if we ended, end
	je .end
	mov byte [di], al ;copy al to di
	inc di
	dec cx
	jmp .loop
.end:
	popa
	ret
	
;in = n/a
;out = nothing too important/critical ;)
io_memory_destroy_table:
	;i feel like i want to destroy my memory table
	;im mad, i want to xor it compleltely
	;and no one is gonna stop me
	; - superleaf1995
	push ax
	push bx
	push cx
	push es
	mov ax, __memory_table__
	mov es, ax
	xor bx, bx
.destroy_entry_number:
	;xor something, (useless since 0.1.5)
	mov word [es:bx], 0
.erase_entries:
	;now lets delete all entries (useless since 0.1.5)
	mov word [es:bx], 0
	inc bx
	cmp bx, 0fffah
	jge .end
	jmp .erase_entries
.end:
	pop es ;done >:)
	pop cx
	pop bx
	pop ax
	ret
	
;in = cx: segment, al: flag
;out = entry in memory table
io_memory_manage:
	push ax
	push bx
	push cx
	push es
	
	cmp cx, 2fffh ;no segments below program memory (3000h)
	jle .error
	jmp .error ;if not a valid flag, bail out
.cont:
	mov byte [.data_flag], byte al
	
	mov word [.data_table_seg], cx

	;segmentate to memory table
	mov ax, __memory_table__
	mov es, ax
	xor bx, bx
.flag_it:
	mov cx, word [.data_table_seg] ;look for segment
	sub cx, 3000h ;substract reserved segments
	mov bx, cx ;bx now points at entry
	
	;set the flag
	mov byte al, [.data_flag]
	mov byte [es:bx], byte al
	
	stc ;sucess!
.end:
	pop es
	pop cx
	pop bx
	pop ax
	ret

.error:
	clc
	jmp .end

	.data_table_seg		dw 0
	.data_flag			db 0
	
;=======================================================================
;
;io.string - manage, search and cut strings at your will
;
;=======================================================================

;in = si: string, cx: place where character should be, al: character to find
;out = flag clear if true, else set if false
io_string_check_character_in_location:
	pusha
	add si, cx
	cmp byte [si], al
	je .yes ;if yes, else do no
.no: ;no character in location
	popa
	stc
	ret
.yes: ;yes
	popa
	clc
	ret
	
;in = si: string 1, di: string 2
;out = carry flag set if equal
io_string_compare:
	pusha
	xor ax, ax ;eliminate any ax left
.loop:
	mov al, byte [si] ;get bytes
	mov ah, byte [di]
	
	cmp al, ah ;are they equal?
	jne near .not_equal
	
	test ax, ax ;did we got a zero?
	jz near .equal

	add si, 1 ;increment one byte...
	add di, 1
	jmp .loop
.not_equal:
	clc
	jmp .end
.equal:
	stc
.end:
	popa
	ret
	
;in = si: string to copy, di: destination
;out = di: string
io_string_copy:
	pusha
.loop:
	lodsb
	
	cmp al, 0
	je .end
	
	stosb
	jmp .loop
.end:
	mov al, 0
	stosb
	popa
	ret
	
;in = si: string, al: character
;out = flag clear is true, else if false
io_string_has_character:
	push ax
	push si
.loop:
	cmp byte [si], 0
	je short .no
	cmp byte [si], al
	je short .yes
	inc si
	jmp short .loop
.no:
	stc
	jmp short .end
.yes:
	clc
.end:
	pop si
	pop ax
	ret
	
;in = si: string
;out = carry flag set if true, else false
io_string_is_empty:
	cmp byte [si], 0
	je short .yes
.no:
	clc
	ret
.yes:
	stc
	ret
	
;in = si: string
;out = cx: lenght of string (does not include null)
io_string_lenght:
	pusha
	xor cx, cx
.loop:
	cmp byte [si], 0 ;if al is zero
	je .end
	
	inc cx ;else keep adding
	inc si
	jmp .loop
.end:
	mov word [.data_lenght], cx
	popa
	mov cx, word [.data_lenght]
	ret
	.data_lenght		dw 0
	
;in = si: string, di: resultant string, al: character to replace, ah: replacement for character al
;out = di: resultant string
io_string_replace_character:
	pusha
	mov dl, al ;save al in dl
	mov dh, ah ;same with ah...
.loop:
	lodsb ;get character, plot it on al
	cmp al, dl ;if al = dl, then we have a character to replace
	je .rep ;time to replace
	cmp al, 0
	je .end
	stosb
	jmp .loop
.rep:
	mov al, dh
	stosb
	jmp .loop
.end:
	mov al, 0
	stosb
	popa
	ret
	
;in = si: string
;out = di: reversed string
io_string_reverse:
	pusha
	call io_string_lenght
	mov word [.data_lenght], cx
	mov di, si
	add di, word [.data_lenght]
	dec di ;do not copy null character
.loop:
	mov al, byte [di]
	mov ah, byte [si]
	mov byte [di], ah
	mov byte [si], al
	inc si
	dec di
	cmp di, si
	ja .loop
.end:
	popa
	ret
	
	.data_lenght dw 0
	
	
;in = si: string, di: tokenized string, al: separator character
;out = di: tokenized string
io_string_tokenize:
	pusha
	mov dl, al ;save al in dl
.loop:
	lodsb ;get character, plot it on al
	cmp al, dl ;if al = dl, then we have a separator!
	je .divide ;time to divide
	cmp al, 0
	je .end
	
	stosb ;if its a normal character just put it
	jmp .loop
.divide:
	mov al, 0 ;make separator into null
	stosb
	jmp .loop
.end:
	mov al, 0
	stosb
	popa
	ret
	
;in = si: keyboard buffer (exprg.com), di: place to put afpfs filename
;out = di: afpfs readable filename (exprg  com)
io_string_to_afpfs_filename:
	pusha
	xor cx, cx ;cx = 0
.loop:
	lodsb
	cmp al, 0 ;null terminator
	je .end
	cmp al, '.' ;dot
	je .space_loop
	cmp cx, 10 ;more than 11 chars
	jge .end
	inc cx
	stosb ;else put the char
	jmp .loop
.space_loop: ;put spaces, until we fit 8.
	cmp cx, 6
	je .loop
	mov al, ' '
	stosb
	inc cx
	cmp cx, 8
	jl .space_loop
	jmp .loop
.end:
	mov al, 0
	stosb
	popa
	ret
	
;=======================================================================
;
;io.system - system related stuff, not os, but rather essential routines
;
;=======================================================================
	
;in = n/a
;out = n/a
io_system_reboot:
	xor ax, ax
	int 19h
	hlt
	
;in = ax: time
;out = n/a
io_system_timer:
	pusha
	test ax, ax
	jz .end ;zero lenght means no action done
	
	mov word [.data_counter], 0 ;save timer in word
	
	mov bx, ax
	xor ax, ax
	mov al, 2
	mul bx
	mov word [data_requested_timer], ax
	
	xor ax, ax
	int 1ah ;get ticks per second
	mov word [data_ticks_per_second], dx
.loop:
	xor ax, ax
	int 1ah
	
	cmp dx, [data_ticks_per_second]
	jne .update
	jmp .loop
.update:
	inc word [.data_counter]
	mov ax, word [.data_counter]
	
	cmp ax, word [data_requested_timer]
	jge .end
	
	mov word [data_ticks_per_second], dx
	
	jmp .loop
	
	.data_counter	dw 0
	
.end:
	popa
	ret
