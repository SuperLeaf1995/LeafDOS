use16
cpu 8086
org 0

jmp short start
nop

;640 KB Disk Specs
oem_label				db "Leaf DOS"
bytes_per_sector		dw 512
sectors_per_cluster		db 1
reserved_for_boot		dw 1
number_of_fats			db 2
root_dir_entries		dw 224
logical_sectors			dw 2880
medium_descriptor_byte	db 0F0h
sectors_per_fat			dw 9
sectors_per_track		dw 18
sides					dw 2
hidden_sectors			dd 0
large_sectors			dd 0
drive_number			dw 0
signature				db 41
volume_id				dd 00000000h
volume_label			db "LD BOOTDISK"
file_system				db "FAT12   "

start:
	mov ax, 07C0h
	add ax, 544
	cli ;set stack segment
	mov ss, ax
	mov sp, 4096
	sti
	mov ax, 07C0h
	mov ds, ax
	
	test dl, dl ;get drive information
	je short .old
	mov [device_number], dl ;set dl to device
	mov ah, 8 ;issue interrupt
	int 13h
	jc info_error ;if error reboot
	and cx, 3Fh ;mask out bits of cx
	mov [sectors_per_track], cx
	;movzx dx, dh ;sides are dh+1
	mov dl, dh ;sides are dh+1
	xor dh, dh
	inc dx
	mov [sides], dx
.old:
	;xor eax eax ;for old BIOSes
	
	clc
	int 12h ;get some memory stuff...
	jc not_engough_memory
	
	cmp ax, 8 ;check if we have 8 kb available
	jl not_engough_memory
	
read_file:
	mov ax, 19 ;read from root directory
	call logical_to_hts ;get parameters for int 13h
	
	mov si, buffer ;sectors of the
	mov ax, ds ;point at our buffer
	mov es, ax ;for storing readed
	mov bx, si ;root directory
	
	mov al, 14 ;read 14 sectors
	call read_sector
	
	mov ax, ds
	mov es, ax
	mov di, buffer
	
	mov cx, word [root_dir_entries]
	xor ax, ax
.find_root_entry:
	xchg cx, dx
	
	mov si, .filename
	mov cx, 11 ;11 characters, the lenght of a FAT12 filename
	rep cmpsb
	je short .file_found ;file found!
	
	add ax, 32 ;skip one root entry
	
	mov di, buffer
	add di, ax
	
	xchg dx, cx
	loop .find_root_entry ;loop...
	jmp no_file ;file not found
.file_found:
	mov ax, word [es:di+0Fh] ;get cluster
	mov word [.cluster], ax
	
	mov ax, 1
	call logical_to_hts
	
	mov di, buffer
	mov bx, di
	
	mov al, 9 ;read all sectors of the FAT
	call read_sector
	
	mov ax, 0500h
	mov es, ax
	xor bx, bx
	
	mov al, 1
	mov ah, 2
	
	push ax
.load_sector:
	mov ax, word [.cluster]
	add ax, 31
	call logical_to_hts
	
	mov ax, 0500h
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
	push cx
	mov cl, 4
	shr ax, cl
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
	add word [.pointer], ax ;bytes
	pop ax
	jmp short .load_sector
.end: ;file is now loaded in the ram
	pop ax ;pop off ax
	mov dl, byte [drive_number] ;give kernel device number
	
	jmp 0500h:0000h ;jump to kernel

.filename			db "KERNEL  SYS"
.cluster			dw 0
.pointer			dw 0

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
	jmp short read_error
.end:
	pop dx
	pop cx
	pop bx
	pop ax
	
	pop ax
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

logical_to_hts:
	push bx
	push ax
	mov bx, ax
	xor dx, dx
	div word [sectors_per_track]
	inc dl
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

not_engough_memory:
	mov si, m_mem
	call print_string
	jmp $
	
no_file:
	mov si, m_no_file
	call print_string
	jmp $

read_error:
	mov si, m_read_error
	call print_string
	jmp $
	
info_error:
	mov si, m_info_error
	call print_string
	jmp $
	
device_number		db 0

m_no_file			db "FILE ERR",0
m_read_error		db "RD ERR",0
m_mem				db "8K MEM REQ",0
m_info_error		db "DP ERR",0
	
times 510-($-$$) db 0
dw 0AA55h
buffer:

