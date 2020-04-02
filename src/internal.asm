;@name:			print_char
;@desc:			prints a char
;@param:		al: character
;@return:		n/a
print_char:
	push ax ;print character right away
	mov ah, 0Eh
	int 10h
	pop ax
	ret

;@name:			print_string
;@desc:			prints a string
;@param:		si: string address
;@return:		n/a
print_string:
	push ax
	push si
	mov ah, 0Eh
.loop:
	lodsb
	
	test al, al ;is character zero?
	jz short .end ;yes, end
	
	int 10h
	jmp short .loop
.end:
	pop si
	pop ax
	ret
	
;@name:			get_input
;@desc:			scans for whole string
;@param:		di: kbuf, bx: max char
;@return:		n/a
get_input:
	pusha
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
	
	call print_char
	
	;now key is in al and ah (only al matters)
	stosb ;place it in tempbuf
	
	inc cx
	
	jmp short .loop
.back:
	mov byte [di], 0
	dec di
	
	mov al, 08h
	call print_char
	mov al, ' '
	call print_char
	mov al, 08h
	call print_char
	
	dec cx
	jmp short .loop
.end:
	xor al, al
	stosb ;place a null terminator
	popa
	ret
	
;@name:			read_file
;@desc:			reads a file
;@param:		si: filename, ax: segment/address to load on
;@return:		n/a
read_file:
	pusha
	
	mov word [.segment], ax
	mov word [.filename], si

	mov ax, 19 ;read from root directory
	call logical_to_hts ;get parameters for int 13h
	
	mov si, buffer ;sectors of the
	mov ax, ds ;point at our buffer
	mov es, ax ;for storing readed
	mov bx, si ;root directory
	
	mov al, 14 ;read 14 sectors
	call read_sector
	jc .error
	
	mov ax, ds
	mov es, ax
	mov di, buffer
	
	mov cx, word [root_dir_entries]
	xor ax, ax
.find_root_entry:
	xchg cx, dx
	
	mov si, [.filename]
	mov cx, 11 ;11 characters, the lenght of a FAT12 filename
	rep cmpsb
	je short .file_found ;file found!
	
	add ax, 32 ;skip one root entry
	
	mov di, buffer
	add di, ax
	
	xchg dx, cx
	loop .find_root_entry ;loop...
	jmp .error ;file not found
.file_found:
	mov ax, word [es:di+0Fh] ;get cluster
	mov word [.cluster], ax
	
	mov ax, 1
	call logical_to_hts
	
	mov di, buffer
	mov bx, di
	
	mov al, 9 ;read all sectors of the FAT
	call read_sector
	jc .error
	
	mov ax, word [.segment]
	mov es, ax
	xor bx, bx
	
	mov al, 1
	mov ah, 2
	
	push ax
.load_sector:
	mov ax, word [.cluster]
	add ax, 31
	call logical_to_hts
	
	mov ax, word [.segment]
	mov es, ax
	mov bx, word [.pointer]
	
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
	mov si, buffer
	add si, ax
	
	mov ax, word [ds:si] ;get cluster word...
	
	or dx, dx ;is our cluster even or odd?
	jz short .even_cluster
.odd_cluster:
	shr ax, 4
	jmp short .check_eof
.even_cluster:
	and ax, 0FFFh
.check_eof:
	mov word [.cluster], ax ;put cluster in cluster
	cmp ax, 0FF8h ;check for eof
	jae short .end
	
	push ax
	mov ax, [bytes_per_sector]
	add word [.pointer], ax ;bytes
	pop ax
	jmp short .load_sector
.end: ;file is now loaded in the ram
	pop ax ;pop off ax
	popa
	clc
	ret
.error:
	popa
	stc
	ret

.filename			dw 0
.segment			dw 0
.cluster			dw 0
.pointer			dw 0
	
;@name:			read_sector
;@desc:			reads a sector
;@param:		int 13h params (see logical_to_hts)
;@return:		cf: set on error
read_sector:
	push ax
	mov ah, 2
	pusha
.loop:
	popa
	pusha
	stc
	int 13h
	jnc short .end
	call reset_drive
	jnc short .loop
	jmp short .error
.end:
	popa
	pop ax
	clc
	ret
.error:
	popa
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
	
;@name:			string_to_fat12
;@desc:			converts a string to FAT12 compatible filename
;@param:		si: string, di: output string
;@return:		n/a
string_to_fat12:
	pusha

	;string_to_upper does not affect DI and SI
	;however, DI contains the uppercased text
	;and SI is the same
	push di
	mov di, .tmpbuf ;save stuff in tmpbuf
	call string_to_upper
	pop di
	mov si, .tmpbuf ;SI now has our tempbuf
	;DI has the original output place for text

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
	popa
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
	mov al, 'E'
	stosb
	mov al, 'X'
	stosb
	mov al, 'E'
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
	
.tmpbuf		times 32 db 0
	
;@name:			string_to_upper
;@desc:			converts a string to all-uppercase
;@param:		si: string, di: output string
;@return:		n/a
string_to_upper:
	pusha
.loop:
	lodsb ;get char from string
	
	test al, al ;is it null string
	jz short .end
	
	call to_upper ;convert char to upper
	
	stosb ;place uppered (or not) char in out string
	
	jmp short .loop
.end:
	popa
	ret

;@name:			to_upper
;@desc:			converts all lowercase into uppercase
;@param:		al: char
;@return:		al: upper char
to_upper:
	cmp al, 'a'
	jge short .is_lower
	jmp short .end
.is_lower:
	cmp al, 'z' ;is it betwen a-z?
	jle short .do_upper ;yes, do a-z
	jmp short .end ;no, go to end
.do_upper:
	sub al, 32 ;convert lowercase into uppercase
.end:
	ret

;@name:			
;@desc:			
;@param:		
;@return:		
