;
; BOOT.ASM
; 
; Bootstraps the KERNEL.SYS
;
; This file is part of LeafDOS
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are
;  met:
;  
;  * Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
;  * Redistributions in binary form must reproduce the above
;    copyright notice, this list of conditions and the following disclaimer
;    in the documentation and/or other materials provided with the
;    distribution.
;  * Neither the name of the  nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;  
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;  

use16
cpu 8086
org 0

jmp short start ; Jump after the MBR
nop

; Floppy Disk MBR table for FAT12
; This are the defaults for a 1.44 MB floppy diskette
; The media descriptor (0F0h) indicates that this is a
; floppy
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
	cli ; Set the stack segment
	mov ss, ax
	mov sp, 4096 ; Set the stack pointer 4096 bytes away from the bootloader
	sti
	mov ax, 07C0h ; Set our data segment
	mov ds, ax ; so we can reference addresses with SI, DI and BX
	
	clc
	int 12h ; Test if the BIOS has engough memory
	jc not_engough_memory
	
	cmp ax, 64 ; Check for 64 kb
	jl not_engough_memory
	
load_kernel:
	mov ax, 19 ; Read root directory
	call logical_to_hts
	
	mov si, buffer
	mov ax, ds
	mov es, ax
	mov bx, si
	
	mov al, 14 ; Read the entire rootdir to get entries
	call read_sector
	
	mov ax, ds
	mov es, ax
	mov di, buffer ; Point at the rootdir
	
	xor ax, ax
.find_root_entry:
	mov si, .filename
	mov cx, 11
	rep cmpsb
	jz short .file_found
	
	add ax, 20h
	
	mov di, buffer
	add di, ax
	
	cmp byte [es:di], 0 ; Check that we didnt finished the rootdir listing
	jnz short .find_root_entry ; checking the first byte of the entry

	jmp no_file ; Kernel not found
.file_found:
	mov ax, word [es:di+0Fh] ; Get cluster from entry
	mov word [.cluster], ax
	
	xor ax, ax
	inc ax
	call logical_to_hts
	
	mov di, buffer
	mov bx, di
	
	mov ax, word [sectors_per_fat] ; Read all the sectors of the FAT
	call read_sector
	
	xor ax, ax
	mov es, ax
	mov bx, 0500h
	
	mov ax, 0201h
	
	push ax
.load_sector:
	mov ax, word [.cluster]
	add ax, 31
	call logical_to_hts
	
	xor ax, ax
	mov es, ax
	mov bx, 0500h
	add bx, word [.pointer]
	
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
	mov bx, 3 ; BX = 3
	mul bx
	dec bx ; BX = 2
	div bx
	
	mov si, buffer
	add si, ax
	
	mov ax, word [ds:si] ; Get cluster word...
	
	or dx, dx ; Is our cluster even or odd?
	jz short .even_cluster
.odd_cluster:
	push cx
	
	mov cl, 4 ; Shift ax to the right (only
	shr ax, cl ; 63 clusters are allowed)
	
	pop cx
	jmp short .check_eof
.even_cluster:
	and ax, 0FFFh
.check_eof:
	mov word [.cluster], ax ; Put cluster in cluster
	cmp ax, 0FF8h ; Check for EOF
	jae short .end ; All loaded, time to jump into kernel
	
	push ax
	mov ax, [bytes_per_sector] ; Go to the next sector
	add word [.pointer], ax
	pop ax
	
	jmp short .load_sector
.end: ; File is now loaded in the ram
	pop ax ; Pop off ax
	mov dl, byte [drive_number] ; Give kernel device number
	
	jmp 0000h:0500h ; Jump to kernel

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

