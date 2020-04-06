;
; KERNEL.ASM
; 
; General system I/O for managing files and applications
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

_KERNEL_			equ 0500h
_DBUFF_				equ 0800h

use16
cpu 8086
org 0500h

jmp short start

jmp run_program
jmp load_file

start:
	xor ax, ax
	cli ; Set our stack
	mov ss, ax
	mov sp, ax
	mov sp, 0FFFFh
	sti
	cld ; Go up in RAM
	xor ax, ax ; Segmentate to
	mov es, ax ; all data and extended segment into the
	mov ds, ax ; kernel segment
	
	mov si, mod_comm
	call run_program
	jc .error

.end:
	jmp $
.error:
	mov ah, 0Eh
	mov al, '!'
	int 10h
	jmp $

mod_comm	db "HIMEM   PRG"

;
; Runs a program.
; As of now it can only load .COM files
;
run_program:
	mov ax, 0A00h
	mov es, ax
	mov ax, 0100h
	call load_file
	jc .error
	
	clc ; Set carry flag to clear
.load_com:
	; TODO: Dynamically load programs
	
	call 0A00h:0100h
.error:
	stc
.end:
	ret
	
;
; Prints string in SI
;
print:
	push ax
	push si
	
	mov ah, 0Eh
.loop:
	lodsb
	
	test al, al
	jz short .end
	
	int 10h

	jmp short .loop
.end:
	pop si
	pop ax
	ret

;
; Loads a file in AX searching for file with the name in SI
; Note: Set ES to desired segment for the file
;
load_file:
	mov word [.offs], ax
	mov word [.filename], si
	
	mov ax, es
	mov word [.segment], ax
	
	call reset_drive
	jc .error

	mov ax, 19 ; Read from root directory
	call logical_to_hts ; Get parameters for int 13h
	
	mov si, _DBUFF_ ; Sectors of the
	mov ax, ds
	mov es, ax
	mov bx, si ; Root directory

	mov al, 14 ; Read 14 sectors
	mov ah, 2
.read_root_dir:
	stc
	int 13h
	jnc short .root_dir_done
	call reset_drive
	jnc short .read_root_dir
	jmp .error
.root_dir_done:
	mov cx, word [root_dir_entries]
	mov bx, -32
.find_root_entry:
	add bx, 32
	
	mov ax, ds
	mov es, ax
	mov di, _DBUFF_
	
	add di, bx
	
	xchg dx, cx

	mov cx, 11 ; Compare filename with entry
	mov si, [.filename]
	rep cmpsb
	je short .file_found
	
	xchg dx, cx
	
	loop .find_root_entry ; Loop...
	
	jmp .error
.file_found:
	mov ax, word [es:di+0Fh] ; Get cluster
	mov word [.cluster], ax
	
	xor ax, ax
	inc ax
	call logical_to_hts
	
	mov di, _DBUFF_
	mov bx, di
	
	mov al, 09h ; read all sectors of the FAT
	mov ah, 2
.read_fat:
	stc
	int 13h
	
	jnc short .fat_done
	call reset_drive
	jnc short .read_fat
	jmp .error
.fat_done:
	mov ax, word [.segment]
	mov es, ax
	mov bx, word [.offs]
	
	mov ax, 0201h
	push ax
.load_sector:
	mov ax, word [.cluster]
	add ax, 31
	call logical_to_hts
	
	mov ax, word [.segment]
	mov es, ax
	mov bx, word [.offs]
	
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
	
	mov si, _DBUFF_
	add si, ax
	
	mov ax, word [ds:si] ; Get cluster word...
	
	or dx, dx ; Is our cluster even or odd?
	jz short .even_cluster
.odd_cluster:
	push cx
	mov cl, 4
	shr ax, cl ; Shift 4 bits ax
	pop cx
	jmp short .check_eof
.even_cluster:
	and ax, 0FFFh
.check_eof:
	mov word [.cluster], ax ; Put cluster in cluster
	cmp ax, 0FF8h ; Check for eof
	jae short .end
	
	push ax
	mov ax, [bytes_per_sector]
	add word [.offs], ax ; Set correct BPS
	pop ax
	
	jmp short .load_sector
.end: ; File is now loaded in the ram
	pop ax ; Pop off ax
	clc
	ret
.error:
	stc
	ret

.filename			dw 0
.segment			dw 0
.offs				dw 0
.cluster			dw 0
.pointer			dw 0

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
