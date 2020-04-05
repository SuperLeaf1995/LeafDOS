use16
cpu 8086
org 0

_KERNEL				equ 0500h
_DBUFF				equ 0800h

start:
	xor ax, ax
	cli ; Set our stack
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh
	sti
	cld ; Go up in RAM
	mov ax, _KERNEL ; Segmentate to
	mov es, ax ; all data and extended segment into the
	mov ds, ax ; kernel segment
	
	mov si, auto_name
	mov ax, 0B00h
	call load_file
	jc .error
	
	call 0B00h

.error:
	jmp $

auto_name		db "COMMAND PRG"

strcmp:
	push ax
	push si
.loop:
	mov al, byte [di]
	mov ah, byte [si]
	
	cmp al, ah
	jne .not_equ
	
	test al, al
	je .equ
	
	loop .loop
.equ:
	stc
	jmp short .end
.not_equ:
	clc
.end:
	pop si
	pop ax
	ret

load_file:
	mov word [.segment], ax
	mov word [.filename], si
	
	call reset_drive
	jc .error
	
	;call printf

	mov ax, 19 ;read from root directory
	call logical_to_hts ;get parameters for int 13h
	
	mov si, _DBUFF ;sectors of the
	mov bx, si ;root directory

	mov al, 14 ;read 14 sectors
	call read_sector
	jc .error
	
	mov cx, word [root_dir_entries]
	mov bx, -32
.find_root_entry:
	add bx, 32
	mov di, _DBUFF
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
	
	xor ax, ax
	inc ax
	call logical_to_hts
	
	mov di, _DBUFF
	mov bx, di
	
	mov al, 09h ;read all sectors of the FAT
	call read_sector
	jc .error
	
	mov bx, word [.segment]
	
	mov ax, 0201h
	
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
	
	mov si, _DBUFF
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
	clc
	ret
.error:
	stc
	ret

.filename			dw 0
.segment			dw 0
.cluster			dw 0
.pointer			dw 0

read_sector:
	push ax
	mov ah, 2
	
	push ax
	push bx
	push cx
.loop:
	pop cx
	pop bx
	pop ax
	
	push ax
	push bx
	push cx
	
	stc
	
	int 13h
	
	jnc short .end
	
	call reset_drive
	jnc short .loop
	
	jmp short .error
.end:
	pop cx
	pop bx
	pop ax
	
	pop ax
	clc
	ret
.error:
	pop cx
	pop bx
	pop ax
	
	pop ax
	stc
	ret

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
