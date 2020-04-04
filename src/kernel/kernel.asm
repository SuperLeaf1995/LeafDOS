use16
cpu 8086
org 0

SEG_KERNEL				equ 0500h ;First free block of mem
SEG_BUFFER				equ	0900h
SEG_AUTORN				equ 1200h
SEG_ARUN				equ 1200h ;overwrite AUTORN, its not needed once a ALOAD is done

start:
	xor ax, ax
	cli ;set the stack
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh
	sti
	cld
	mov ax, SEG_KERNEL ;segmentate to
	mov es, ax ;all data and extended segment into the
	mov ds, ax ;kernel segment
	
	clc ;check if we have engough memory for our
	int 12h ;programs and buffers
	jc .error
	
	cmp ax, 64 ;check for 64 kb
	jl .error
	
	test dl, dl ;get drive information
	je short .old
	mov [device_number], dl ;set dl to device
	mov ah, 8 ;issue interrupt
	int 13h
	jc short .old ;if error reboot
	and cx, 3Fh ;mask out bits of cx
	mov [sectors_per_track], cx
	;movzx dx, dh ;sides are dh+1
	mov dl, dh ;sides are dh+1
	xor dh, dh
	inc dx
	mov [sides], dx
.old:
	;xor eax eax ;for old BIOSes

	mov si, moduler_ok
	call printf
	
	mov ax, SEG_AUTORN ;autorun loads at 4000h
	mov si, autorun_file
	call fopen
	jc .end
	
	mov si, SEG_AUTORN ;now read autorun.lss
	call printf
.read_loop:
	cmp al, byte [si]
	jz .end
	
	mov cx, 4
	mov di, .arun_str
	call strncmp
	jc .arun
	
	inc si

	jmp short .read_loop
.arun: ;ARUN - Run program
	add si, 4 ;skip ARUN
.rem_white:
	inc si
	lodsb
	cmp al, ' '
	je short .rem_white
	dec si
	
	mov ax, SEG_ARUN ;normal place to load stuff on
	call printf
	
	call fopen
	jc .arun_error
	
	call SEG_ARUN
	
	ret ;after (arun SOMENAMEPRG) end
.arun_error:
	mov si, .arun_err
	call printf
	jmp $
	
;general LSS parser errors
.end:
	mov si, .end_err
	call printf
	jmp $
.error:
	mov si, .erro
	call printf
	jmp $

.arun_err		db "ARUN ERR",0Dh,0Ah,0
.arun_str		db "ARUN",0

.end_err		db "AUTORUN.LSS MUST HAVE ARUN",0Dh,0Ah,0
.erro			db "I/O ERROR",0Dh,0Ah,0
		
autorun_file	db "AUTORUN LSS"
moduler_ok		db "Moduler: OK",0Dh,0Ah,0

strncmp:
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
	jmp short .equ
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

printf:
	push si
	push ax
	mov ah, 0Eh
.loop:
	lodsb
	
	test al, al ;is character zero?
	jz short .end ;yes, end

	int 10h

	jmp short .loop
.end:
	pop ax
	pop si
	ret ;ret popf off the return address

fopen:
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

root_dir_entries		dw 224
bytes_per_sector		dw 512
sectors_per_track		dw 18
sides					dw 2
device_number			db 0
