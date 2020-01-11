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
	
;=======================================================================
;io.disk
;=======================================================================
	
[segment .text]

;in = si: filename, bx: offset to load file to
;out = cf: clear if found
io_disk_find_file:
	mov word [.filename], si
	mov word [.offs], bx
	
	mov si, __buffer__ ;make everything to point at disk buffer
	mov bx, si
	
	mov ax, 1 ;start from first sector
	call near io_disk_logical_to_hts
	
	mov al, 25 ;read some sectors...
	pusha
.read_disk:
	popa
	pusha
	
	call io_disk_read_sector
	
	jnc short .prepare_buffer
	call near io_disk_reset ;error on disk?
	jnc short .read_disk
	;error
	stc
	ret
.prepare_buffer:
	popa
	pusha
	mov di, __buffer__
	xor ax, ax
	mov word [.sect], ax ;sector is zero, for now
.find_filename:
	add word [.sect], 1 ;add one sector per loop
	mov cx, 512 ;read sector per sector
.loop:
	xchg cx, dx
	mov si, data_program_to_load
	mov cx, 9
	rep cmpsb
	je short .found_file
	add ax, 1
	mov di, __buffer__
	add di, ax
	xchg dx, cx
	loop .loop
	cmp word [.sect], 25 ;more than total sectors!
	jge short .not_found
	jmp short .find_filename ;another sector...
.found_file:
	popa
	clc
	retn

.not_found:
	popa
	stc
	retn
	
[segment .bss]
	
	.ptr						resw 1
	.sect						resw 1
	.filename					resw 1
	.offs						resw 1
	
;in = di: place to put file list
;out = cf: clear if sucess, di: file list, sperated by commas
io_disk_get_file_list:
	mov word [.list_loc], di ;save where to put list
	mov ax, 1
	call near io_disk_logical_to_hts
	mov si, __buffer__ ;make int 13h put stuff on our buffer
	mov bx, si
	
	mov ah, 2
	mov al, __all_sectors__ ;read some sectors
	pusha
	
.read_disk:
	popa
	pusha
	
	stc
	int 13h
	jnc short .find_files
	call near io_disk_reset
	jnc short .read_disk
	
	jmp short .err
.find_files:
	popa
	mov cx, 4096
	mov si, bx
.find_eof:
	lodsw ;get word
	
	cmp ax, 0ff8h
	je short .found_eof
	
	inc bx ;increment bx, aka buffer location
	inc bx ;by a word...
	
	loop .find_eof ;loop a lot
	jmp short .err
	
.found_eof:
	mov word [.first_eof_loc], bx ;save first eof location
	mov si, bx ;put bx in si
	mov di, word [.list_loc]
	
	mov cx, __afpfs_default__
.read_filename:
	;read first filename...
	lodsb ;get filename...
	stosb ;save filename...
	inc bx ;incrmeent bx like di, so we help find_next_eof
	loop .read_filename
	
	mov al, ','
	stosb ;place a separator
	
	jmp short .find_next_eof
	
.find_next_eof:
	mov cx, 4096
	mov si, bx ;place bx in si
	mov di, bx ;do an ok
.next:
	lodsw ;get word
	
	cmp ax, 0ff8h
	je short .read_filename ;eof found, now read filename
	
	loop .next
	jmp short .end ;no eof found? bail out!
	
.end:
	;place a null thingy
	xor al, al
	stosb ;done
	
	popa
	clc
	retn
	
[segment .bss]
	
	.list_loc					resw 1
	.first_eof_loc				resw 1
	
[segment .text]
	
.err:
	popa
	stc
	retn
	
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
	
;in = si: filename, bx: offset to load file to
;out = cf: clear if sucess
io_disk_read_file:
	mov word [.filename], si
	mov word [.offs], bx
	
	mov si, __buffer__ ;make everything to point at disk buffer
	mov bx, si
	
	mov ax, 1 ;start from first sector
	call near io_disk_logical_to_hts
	
	mov al, 25 ;read some sectors...
	pusha
.read_disk:
	popa
	pusha
	
	call io_disk_read_sector
	
	jnc short .prepare_buffer
	call near io_disk_reset ;error on disk?
	jnc short .read_disk
	;error
	stc
	ret
.prepare_buffer:
	popa
	pusha
	mov di, __buffer__
	xor ax, ax
	mov word [.sect], ax ;sector is zero, for now
.find_filename:
	add word [.sect], 1 ;add one sector per loop
	mov cx, 512 ;read sector per sector
.loop:
	xchg cx, dx
	mov si, data_program_to_load
	mov cx, 9
	rep cmpsb
	je short .found_file
	add ax, 1
	mov di, __buffer__
	add di, ax
	xchg dx, cx
	loop .loop
	cmp word [.sect], 25 ;more than total sectors!
	jge short .not_found
	jmp short .find_filename ;another sector...
.found_file:
	mov bx, word [.offs]

	mov ax, word [.sect] ;sector where file is
	call near io_disk_logical_to_hts
	
	mov al, 10 ;read this many sectors, again...
	call io_disk_read_sector
	
	jnc short .end
	call near io_disk_reset ;if there is error, reset floppY
	jmp short .found_file
.end:
	popa
	
	;remove filename from data
	pusha
	mov si, __program__+__afpfs_default__ ;eliminate file metadata
	mov di, __program__ ;put to first byte
	mov cx, 8192
	call near io_memory_copy
	popa
	
	clc
	retn
	
.not_found:
	popa
	stc
	retn
	
[segment .bss]
	
	.ptr						resw 1
	.sect						resw 1
	.filename					resw 1
	.offs						resw 1
	
[segment .text]
	
;in = [es:bx] place to plot sector data, cl: no. of sectors to read
;out = carry flag clear if not ok
io_disk_read_sector:
	pusha
	mov ah, 02h
	stc
	int 13h
	popa ;incase registers where altered
	ret
	
;in = n/a
;out = n/a
io_disk_reset:
	push ax
	push dx
	
	xor ax, ax
	mov dl, byte [disk_drive_number]
	stc
	int 13h
	
	pop dx
	pop ax
	retn
	
;=======================================================================
;io.display
;=======================================================================
	
;in = n/a
;out =	al:	Adapter Vendor
;		ah: Revision
;Table of returns
;AL				AH
;00h			00h		AHEAD Video Adapter
;01h			00h		Paradise Video Adapter
;02h			00h		Oak Tech Video Adapter
;ffh			ffh		Unknown Adapter
io_display_check_video_adapters:
	push es
	;first check for AHEAD adapters
	mov ax, 0C000h
	mov es, ax
	mov si, 0025h ;C000h:0025h
	
	xor ah, ah ;clear ah
	
	mov al, byte [si]		;A
	push ax
	mov al, byte [si+1]		;H
	push ax
	mov al, byte [si+2]		;E
	push ax
	mov al, byte [si+3]		;A
	push ax
	mov al, byte [si+4]		;D
	push ax
	jmp .check_ahead_adapter
	
.no_ahead_adapter:
	;there are no AHEAD adapters
	
	;check for paradise adapters
	mov si, 007dh	;C000h:007dh
	
	mov al, byte [si]		;V
	push ax
	mov al, byte [si+1]		;G
	push ax
	mov al, byte [si+2]		;A
	push ax
	mov al, byte [si+3]		;=
	push ax
	
	jmp .check_paradise_adapter
	
.no_paradise_adapter:
	;there are no paradise adapters
	
	;check for oak tech adapters
	mov si, 0008h
	
	mov al, byte [si]		;O
	push ax
	mov al, byte [si]		;A
	push ax
	mov al, byte [si]		;K
	push ax
	mov al, byte [si]		;space
	push ax
	mov al, byte [si]		;V
	push ax
	mov al, byte [si]		;G
	push ax
	mov al, byte [si]		;A
	push ax
	
	jmp .check_oak_tech_adapter
	
.no_oak_tech_adapter:
	;there are no oak tech adapters
	
	mov al, 0ffh ;unknown
	mov ah, 0ffh
	
.end:
	pop es
	ret
	
.check_ahead_adapter:
	pop ax ;get stuff back
	cmp al, 'D'
	jne .no_ahead_adapter
	
	pop ax
	cmp al, 'A'
	jne .no_ahead_adapter
	
	pop ax
	cmp al, 'E'
	jne .no_ahead_adapter
	
	pop ax
	cmp al, 'H'
	jne .no_ahead_adapter
	
	pop ax
	cmp al, 'A'
	jne .no_ahead_adapter
	
	xor al, al	;al = 00h
	xor ah, ah	;ah = 00h
	
	jmp .end ;give result to caller
	
.check_paradise_adapter:
	pop ax ;get stuff back
	cmp al, '='
	jne .no_paradise_adapter
	
	pop ax
	cmp al, 'A'
	jne .no_paradise_adapter
	
	pop ax
	cmp al, 'G'
	jne .no_paradise_adapter
	
	pop ax
	cmp al, 'V'
	jne .no_paradise_adapter
	
	mov al, 1	;al = 01h
	xor ah, ah	;ah = 00h
	
	jmp .end ;give result to caller
	
.check_oak_tech_adapter:
	pop ax ;get stuff back
	cmp al, 'A'
	jne .no_oak_tech_adapter
	
	pop ax
	cmp al, 'G'
	jne .no_oak_tech_adapter
	
	pop ax
	cmp al, 'V'
	jne .no_oak_tech_adapter
	
	pop ax
	cmp al, ' '
	jne .no_oak_tech_adapter
	
	pop ax
	cmp al, 'K'
	jne .no_oak_tech_adapter
	
	pop ax
	cmp al, 'A'
	jne .no_oak_tech_adapter
	
	pop ax
	cmp al, 'O'
	jne .no_oak_tech_adapter
	
	mov al, 2	;al = 02h
	xor ah, ah	;ah = 00h
	
	jmp .end ;give result to caller
	
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
	je short .end
	
	mov word [es:di], cx ;repeat...
	
	inc di ;advance by a word
	inc di
	
	jmp short .loop
.end:
	pop es
	popa
	ret
	
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
	
[segment .bss]
	.data_end		resb 1
	.data_start		resb 1
	
[segment .text]
	
;in = ax: x, bx: y
;out = dl: colour
io_display_get_pixel:
	pusha
	push es
	push ax
	push dx
	mov ax, word [data_graphics_memory]
	mov es, ax ;point to the graphical memory (cga/vga/tandy/hercules, etc)
	
	test bx, bx
	jz short .first_line
	
	mov ax, word [data_graphics_mode_wide]
	mul bx ;y*wide = addr-x
	mov cx, ax ;save result in cx
	
.first_line:
	pop dx
	pop ax ;get the original x back
	
	add cx, ax ;(y*tall)+x = addr
	mov si, cx ;tell si we want to get something from addr
	
	lodsb ;put the stuff in al
	
	mov dl, al ;plot in dl, because print_pixel
	
	pop es
	popa
	ret
	
;in = n/a
;out = al:	feh = Mono
;			ffh = Colour
io_display_get_current_video_mode:
	push bx
	
	mov ah, 0fh
	int 10h
	
	cmp al, 03h
	je short .color
	
	cmp al, 07h
	je short .mono
	jmp short .end
.mono:
	mov al, 0feh
	jmp short .end
.color:
	mov al, 0ffh
	jmp short .end
.end:
	pop bx
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
	
	push ax
	mov al, byte [data_text_mode_wide]
	mov ah, byte [data_text_x]
	cmp ah, al
	jae short .wrap
	pop ax
	
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
	call near io_display_scroll_down
	inc byte [data_text_x]
	jmp short .end
.wrap:
	pop ax
	stosw
	inc byte [data_text_y]
	mov byte [data_text_x], 0
	jmp short .end
.newline:
	inc byte [data_text_y]
	mov byte [data_text_x], 0
	jmp short .end
.end:
	pop es
	popa
	ret
	
[segment .bss]
	.data_character	resb 1
	
[segment .text]
	
;in = ax: x, bx: y, dl: colour
;out = n/a
io_display_print_pixel:
	pusha
	push es
	push ax
	push dx
	mov ax, word [data_graphics_memory]
	mov es, ax ;point to the graphical memory (cga/vga/tandy/hercules, etc)
	
	test bx, bx
	jz short .first_line
	
	mov ax, word [data_graphics_mode_wide]
	mul bx ;y*wide = addr-x
	mov cx, ax ;save result in cx
	
.first_line:
	pop dx
	pop ax ;get the original x back
	
	add cx, ax ;(y*tall)+x = addr
	mov di, cx ;tell di we want to put something in addr
	
	mov al, dl ;color of pixel
	stosb ;place al
	
	pop es
	popa
	ret
	
;in = si: string
;out = n/a
io_display_print_text:
	push ax
.loop:
	lodsb
	
	test al, al
	jz short .end
	
	call near io_display_print_char ;print a char
	jmp short .loop
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
	
	movzx si, byte [data_text_mode_wide]
	shl si, 1
	
.loop:
	mov ax, word [es:si] ;get word below
	mov word [es:di], ax ;place the word in dest.
	
	cmp bx, 2000
	jae short .end
	
	inc bx
	
	inc si
	inc si
	
	inc di
	inc di
	
	jmp short .loop
.end:
	
	mov al, byte [data_text_mode_tall] ;tall-1 = new position
	dec al
	mov byte [data_text_y], al
	mov byte [data_text_x], 0
	
	pop es
	popa
	ret
	
;in = al: video mode
;out = n/a
io_display_set_video_mode:
	pusha
	
	xor ah, ah ;ah 00h
	int 10h ;do the interrupt
	
	popa ;restore registers
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
;io.keyboard
;=======================================================================
	
;in = ch: number of chars to read, di: buffer
;out = di: string
io_keyboard_input:
	pusha
	xor cl, cl
.loop:
	call near io_keyboard_keypress
	
	push bx
	mov bl, byte [data_text_x]
	mov bh, byte [data_text_y]
	call near io_display_update_text_mode_cursor
	pop bx
	
	cmp al, 10 ;newline (enter)
	je short .end
	cmp al, 13
	je short .end
	cmp al, 8 ;backspace
	je short .back
	cmp cl, ch ;did we inputed more chars than the ones we should?
	jae short .end
.print_part:
	call io_display_print_char
	inc cl
	stosb
	jmp short .loop
.back:
	cmp cl, 0 ;remove character from string
	je short .loop ;keep cursor from choking
	dec di
	mov byte [di], 0
	dec cl
	
	mov al, 8 ;retroceed one character
	call near io_display_print_char
	mov al, ' ' ;display a space
	call near io_display_print_char
	mov al, 8 ;when we displayed a space we advanced a character, go and retroceed again...
	call near io_display_print_char
	
	push bx
	mov bl, byte [data_text_x]
	mov bh, byte [data_text_y]
	call near io_display_update_text_mode_cursor ;update cursor, so it dosent chokes
	pop bx
	jmp short .loop
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
;io.memory
;=======================================================================
	
;in = n/a
;out = ax: kib of memory, cf: sucess/err
io_memory_check_low_memory:
	clc
	int 20h
	ret
	
;in = si: source, di: destination, cx: bytes to copy
;out = n/a
io_memory_copy:
	pusha
.loop:
	lodsb ;get and
	stosb ;put
	
	loop .loop
.end:
	popa
	retn

;in = al: byte to copy, di: destination, cx: times to copy char
;out = n/a
io_memory_copy_byte:
	pusha
.loop:
	cmp cx, 0 ;if we ended, end
	je short .end
	mov byte [di], al ;copy al to di
	inc di
	dec cx
	jmp short .loop
.end:
	popa
	ret
	
;=======================================================================
;io.parallel
;=======================================================================
	
;in = n/a
;out = cl: number of available ports
io_parallel_ports_check:
	push ax
	push bx
	push es
	
	xor cl, cl
	
	mov ax, 0040h
	mov es, ax
	
	mov bx, 08h
	mov ax, word [es:bx] ;get first parallel word...
	test ax, ax
	jz short .end
	inc cl ;cl = 1
	
	mov bx, 0ah
	mov ax, word [es:bx] ;get second parallel word...
	test ax, ax
	jz short .end
	inc cl ;cl = 2
	
	mov bx, 0ch
	mov ax, word [es:bx] ;get third parallel word...
	test ax, ax
	jz short .end
	inc cl ;cl = 3
	
	mov bx, 0eh
	mov ax, word [es:bx] ;get fourth parallel word...
	test ax, ax
	jz short .end
	inc cl ;cl = 4
	
.end:
	pop es
	pop bx
	pop ax ;restore all registers
	ret
	
;=======================================================================
;io.serial
;=======================================================================
	
;in = dx: port number
;out = n/a
io_serial_enable:
	pusha
	
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
	
	popa
	ret
	
;in = dx: port address
;out = al: byte
io_serial_get_byte:
	push dx
.loop:
	add dx, 5
	in al, dx ;put stuff got from dx to al
	and al, 1
	jz short .loop
	
	sub dx, 5
	
	in al, dx
	pop dx
	ret
	
;in = n/a
;out = al: number of serial ports
io_serial_ports_check:
	push es
	pusha
	
	mov ax, 0040h
	mov es, ax
	xor bx, bx
	
	mov ax, word [es:bx] ;get first serial port
	test ax, ax
	jz short .no_first_serial_port ;nope
	;we have serial ports!
.yes_first_serial_port:
	mov bx, 2
	
	mov ax, word [es:bx] ;get second serial port
	test ax, ax
	jz short .no_second_serial_port ;no
.yes_second_serial_port:
	mov bx, 4
	
	mov ax, word [es:bx] ;get third serial port
	test ax, ax
	jz short .no_third_serial_port ;ok, no 3rd port
.yes_third_serial_port:
	mov bx, 6
	
	mov ax, word [es:bx] ;get fourth serial port
	test ax, ax
	jz short .no_third_serial_port ;oh, almost all ports
	mov byte [.data_ports], 4 ;all ports!
.end:
	popa
	pop es ;segment restored!
	mov al, byte [.data_ports]
	ret
	
.no_first_serial_port:
	mov byte [.data_ports], 0 ;zero ports, if there is no registry here
	jmp short .end
.no_second_serial_port:
	mov byte [.data_ports], 1 ;only one port
	jmp short .end
.no_third_serial_port:
	mov byte [.data_ports], 2 ;only two ports
	jmp short .end
.no_fourth_serial_port:
	mov byte [.data_ports], 3 ;only three ports
	jmp short .end
	
[segment .bss]
	
	.data_ports	resb 1
	
[segment .text]
	
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
	call near io_serial_send_byte
	
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
	call near io_serial_send_byte
	
	call near io_serial_get_byte ;get reply...
	cmp al, 01ah ;computer is stupid and didnt understood
	jne short .error
	
	;else if computer 2 understood...
	mov al, 019h ;send byte of "size of packet"
	call near io_serial_send_byte
	
	call near io_serial_get_byte ;get reply...
	cmp al, 01bh ;how many the odds?
	jne short .error
	
	;at this point, we will send a unsigned byte dicating the size of
	;our packet
	mov al, cl ;put size in al
	call near io_serial_send_byte
	
	call near io_serial_get_byte
	cmp al, 01ah
	jne short .error
	
	;now its time to send the actual data
	popa ;registers where oofed while we did this initialization
	pusha
.loop:
	cmp cx, 0 ;if counter is zero, end
	je short .end
	
	lodsb ;get byte and send it
	call near io_serial_send_byte
	
	dec cx
	jmp short .loop
.end:
	mov al, 01ah ;lets make sure computer finished analyzing data...
	call near io_serial_send_byte
	
	call near io_serial_get_byte ;get reply...
	
	cmp al, 0bbh ;error, data trown or destroyed
	je short .error
	
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
	call near io_serial_get_byte ;get "data incoming" byte
	cmp al, 017h
	jne short .abort
	
	mov al, 01ah ;send reply of "ok" byte
	call near io_serial_send_byte
	
	call near io_serial_get_byte
	cmp al, 019h ;get "size of packet" byte
	jne short .abort
	
	mov al, 01bh ;send reply of "ok gimme data naw"
	call near io_serial_send_byte
	
	call near io_serial_get_byte ;get size of packet to be sent
	
	;hmm is this bigger than the buffer we allow!?
	cmp cl, al
	jl short .abort
	
	mov ch, al ;store size in ch, for future use
	
	;nope, proceed
	;send reply byte "ok i got ur stuff, now gimme me actual data naw"
	mov al, 01ah
	call near io_serial_send_byte
	popa
	pusha
	xor cl, cl ;set cl to zero
.get_bytes:
	cmp cl, ch
	je short .abort
	
	lodsb
	call near io_serial_send_byte
	
	inc cl ;decrement counter...
	
	jmp short .get_bytes
	
.end:
	;when we finished receiving data, now we must send the "ok, finish"
	;byte
	call near io_serial_get_byte
	
	cmp al, 01ah
	jne short .abort
	
	mov al, 0bbh
	call near io_serial_send_byte ;done
	popa ;we finished!
	clc
	ret
	
.abort:
	mov al, 0feh ;send error byte (auto cancels everything)
	call near io_serial_send_byte
	
	popa
	stc
	ret
	
;=======================================================================
;io.string
;=======================================================================
	
;in = si: string, cx: place where character should be, al: character to find
;out = flag clear if true, else set if false
io_string_check_character_in_location:
	pusha
	add si, cx
	cmp byte [si], al
	je short .yes ;if yes, else do no
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
	jne short .not_equal
	
	test ax, ax ;did we got a zero?
	jz short .equal

	add si, 1 ;increment one byte...
	add di, 1
	jmp short .loop
.not_equal:
	clc
	jmp short .end
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
	je short .end
	
	stosb
	jmp short .loop
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
	je short .end
	
	inc cx ;else keep adding
	inc si
	jmp short .loop
.end:
	mov word [.data_lenght], cx
	popa
	mov cx, word [.data_lenght]
	ret
	
[segment .bss]
	
	.data_lenght		resw 1
	
[segment .text]
	
;in = si: string, di: resultant string, al: character to replace, ah: replacement for character al
;out = di: resultant string
io_string_replace_character:
	pusha
	mov dl, al ;save al in dl
	mov dh, ah ;same with ah...
.loop:
	lodsb ;get character, plot it on al
	cmp al, dl ;if al = dl, then we have a character to replace
	je short .rep ;time to replace
	cmp al, 0
	je short .end
	stosb
	jmp short .loop
.rep:
	mov al, dh
	stosb
	jmp short .loop
.end:
	mov al, 0
	stosb
	popa
	ret
	
;in = si: string
;out = di: reversed string
io_string_reverse:
	pusha
	call near io_string_lenght
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
	ja short .loop
.end:
	popa
	ret
	
[segment .bss]
	
	.data_lenght resw 1
	
[segment .text]
	
;in = si: string, al: separator character
;out = ax: str 1, bx: 2, cx: 3, etc Null if no string
io_string_tokenize:
	push di ;only push indexes, regs are gonna get rekt
	push si
	
	mov byte [.char], al
	
	xor dx, dx ;clear all registers
	xor cx, cx
	xor bx, bx
	xor ax, ax
	
.loop:
	lodsb
	
	cmp byte [.char], al ;if the separator is reached...
	je short .div_string
	
	test al, al ;if null character, end
	jz short .end
	
	jmp short .loop
.div_string:
	mov ax, si ;put stuff in ax
.loop_2:
	lodsb
	
	cmp byte [.char], al ;if the separator is reached...
	je short .div_string_2
	
	test al, al ;if null character, end
	jz short .end
	
	jmp short .loop_2
.div_string_2:
	mov bx, si ;put stuff in bx
.loop_3:
	lodsb
	
	cmp byte [.char], al ;if the separator is reached...
	je short .div_string_3
	
	test al, al ;if null character, end
	jz short .end
	
	jmp short .loop_3
.div_string_3:
	mov cx, si ;put stuff in cx
.loop_4:
	lodsb
	
	cmp byte [.char], al ;if the separator is reached...
	je short .div_string_4
	
	test al, al ;if null character, end
	jz short .end
	
	jmp short .loop_4
.div_string_4:
	mov dx, si ;put stuff in dx
.end:
	pop si
	pop di
	ret
	
segment .bss
	
	.char	resb 1
	
[segment .text]
	
;in = si: keyboard buffer (exprg.com), di: place to put afpfs filename
;out = di: afpfs readable filename (exprg  com)
io_string_to_afpfs_filename:
	pusha
	xor cx, cx ;cx = 0
.loop:
	lodsb
	cmp al, 0 ;null terminator
	je short .end
	cmp al, '.' ;dot
	je short .space_loop
	cmp cx, 10 ;more than 11 chars
	jge short .end
	inc cx
	stosb ;else put the char
	jmp short .loop
.space_loop: ;put spaces, until we fit 8.
	cmp cx, 6
	je short .loop
	mov al, ' '
	stosb
	inc cx
	cmp cx, 8
	jl short .space_loop
	jmp short .loop
.end:
	mov al, 0
	stosb
	popa
	ret
	
;=======================================================================
;io.system
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
	jz short .end ;zero lenght means no action done
	
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
	jne short .update
	jmp short .loop
.update:
	inc word [.data_counter]
	mov ax, word [.data_counter]
	
	cmp ax, word [data_requested_timer]
	jge short .end
	
	mov word [data_ticks_per_second], dx
	
	jmp short .loop
	
[segment .bss]
	
	.data_counter	resw 1
	
[segment .text]
	
.end:
	popa
	ret
