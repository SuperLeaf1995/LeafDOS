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
	
	mov si, buffer ;sectors of the
	mov bx, si ;root directory
	
	mov al, 14 ;read 14 sectors
	call read_sector
	jc .error
	
	mov cx, word [root_dir_entries]
	mov bx, -32
.find_root_entry:
	add bx, 32
	mov di, buffer
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
	
	mov di, buffer
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
	mov si, buffer
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
	
	mov si, buffer ;sectors of the
	mov bx, si ;root directory
	
	mov al, 14 ;read 14 sectors
	call read_sector
	jc .error
	
	mov cx, word [root_dir_entries]
	mov bx, -32
.find_root_entry:
	add bx, 32
	mov di, buffer
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
	
.tmpbuf		times 32 db 0
