;
; DEV.COM
;
; Detects devices and loads appropiate drivers (must run in same segment
; as the kernel)
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
org 5000h ; Special kernel program

_DBUFF_				equ 0A00h

start:
	; We are in segment 0 already!
	
;
; Detect VGA
;
.vga:
	mov ah, 0Fh
	int 10h
	
	; Detect VGA, is it color capable?
	cmp al, 7
	jne short .color_vga
.mono_vga:
	mov si, deb1
	call print
	xor ah, ah ; AH = 0
	mov byte [videoMainSrc], ah
	jmp short .serial
.color_vga:
	mov si, deb2
	call print
	xor ah, ah ; AH = 1
	inc ah
	mov byte [videoMainSrc], ah

;
; Detect serial and parallel ports
;
.serial:
	mov di, 0400h ; Get serial info
	
	mov ax, word [di+00h]
	mov word [serialAddr_1], ax
	test ax, ax
	jnz short .yes_serial_1
	jmp short .serial_2
.yes_serial_1:
	mov si, deb3
	call print
.serial_2:
	mov ax, word [di+02h]
	mov word [serialAddr_2], ax
	test ax, ax
	jnz short .yes_serial_2
	jmp short .serial_3
.yes_serial_2:
	mov si, deb4
	call print
.serial_3:
	mov ax, word [di+04h]
	mov word [serialAddr_3], ax
	test ax, ax
	jnz short .yes_serial_3
	jmp short .serial_4
.yes_serial_3:
	mov si, deb5
	call print
.serial_4:
	mov ax, word [di+06h]
	mov word [serialAddr_4], ax
	test ax, ax
	jnz short .yes_serial_1
	jmp short .para_1
.yes_serial_4:
	mov si, deb6
	call print
.para_1:
	mov ax, word [di+08h] ; Get parallel ports info
	mov word [parallelAddr_1], ax
	test ax, ax
	jnz short .yes_para_1
	jmp short .para_2
.yes_para_1:
	mov si, deb7
	call print
.para_2:
	mov ax, word [di+0Ah]
	mov word [parallelAddr_2], ax
	test ax, ax
	jnz short .yes_para_2
	jmp short .para_3
.yes_para_2:
	mov si, deb8
	call print
.para_3:
	mov ax, word [di+0Ch]
	mov word [parallelAddr_3], ax
	test ax, ax
	jnz short .yes_para_1
	jmp short .end_ser
.yes_para_3:
	mov si, deb9
	call print
.end_ser:
	mov si, debA
	call print
	
	call list_files
	
	mov si, autorun
	mov di, tmpbuf
	call strfat12

	mov si, di
	mov ax, 1FFFh
	call load_file
	jc .error

	mov si, di
	call print
	
	mov si, 1FFFh
	call print
.end:
	ret
	
.error:
	mov si, debB
	call print
	jmp short .end
	
autorun	db	"autorun.lss"
deb1	db	"Detected: MONOCHROME MONITOR",0Dh,0Ah,00h
deb2	db	"Detected: COLOR MONITOR",0Dh,0Ah,00h
deb3	db	"Detected: SERIAL PORT 1",0Dh,0Ah,00h
deb4	db	"Detected: SERIAL PORT 2",0Dh,0Ah,00h
deb5	db	"Detected: SERIAL PORT 3",0Dh,0Ah,00h
deb6	db	"Detected: SERIAL PORT 4",0Dh,0Ah,00h
deb7	db	"Detected: PARALLEL PORT 1",0Dh,0Ah,00h
deb8	db	"Detected: PARALLEL PORT 2",0Dh,0Ah,00h
deb9	db	"Detected: PARALLEL PORT 3",0Dh,0Ah,00h
debA	db	"Loading device drivers",0Dh,0Ah,00h
debB	db	"Error!",0Dh,0Ah,00h
	
tmpbuf	times 64 db 0

root_dir_entries		dw 224
bytes_per_sector		dw 512
sectors_per_track		dw 18
sides					dw 2
device_number			db 0

;
; Lists all files
;
list_files:
	stc
	call reset_drive
	jc .error

	mov ax, 19 ; Read from root directory
	call logical_to_hts ; Get parameters for int 13h
	
	mov si, _DBUFF_ ; Read the root directoy and place
	mov ax, ds ; It on the disk buffer
	mov es, ax
	mov bx, si

	mov al, 14 ; Read 14 sectors
	mov ah, 2
	
.read_root_dir:
	push dx ; Save DX from destruction in some bioses
	cli ; Disable interrupts to not mess up
	
	stc ; Set carry flag (some BIOSes do not set it!)
	int 13h
	
	sti ; Enable interrupts again
	pop dx
	
	jnc short .root_dir_done ; If everything was good, go to find entries
	
	call reset_drive
	jnc short .read_root_dir
	
	jmp .error
.root_dir_done:
	cmp al, 14 ; Check that all sectors have been read
	jne .error

	mov cx, word [root_dir_entries]
	mov bx, -32
	mov ax, ds
	mov es, ax
.find_root_entry:	
	add bx, 32
	mov di, _DBUFF_
	
	add di, bx
	
	cmp byte [di], 000h
	je short .skip_entry
	
	cmp byte [di], 0E5h
	je short .skip_entry
	
	cmp byte [di+11], 0Fh
	je short .skip_entry
	
	cmp byte [di+11], 08h
	je short .skip_entry
	
	cmp byte [di+11], 00111111b
	je short .skip_entry
	
	push si
	mov si, di
	call print_fat12
	mov si, newline
	call print
	pop si

.skip_entry:
	loop .find_root_entry ; Loop...
.error:
	ret

newline				db 0Dh,0Ah,00h

;
; Loads a file in AX searching for file with the name in SI
; Note: Set ES to desired segment for the file
;
load_file:
	mov word [.offs], ax
	mov word [.filename], si
	
	mov ax, es
	mov word [.segment], ax
	
	stc
	call reset_drive
	jc .error

	mov ax, 19 ; Read from root directory
	call logical_to_hts ; Get parameters for int 13h
	
	mov si, _DBUFF_ ; Read the root directoy and place
	mov ax, ds ; It on the disk buffer
	mov es, ax
	mov bx, si

	mov al, 14 ; Read 14 sectors
	mov ah, 2
	
.read_root_dir:
	push dx ; Save DX from destruction in some bioses
	cli ; Disable interrupts to not mess up
	
	stc ; Set carry flag (some BIOSes do not set it!)
	int 13h
	
	sti ; Enable interrupts again
	pop dx
	
	push si
	mov si, [.filename]
	call print
	pop si
	
	jnc short .root_dir_done ; If everything was good, go to find entries
	
	call reset_drive
	jnc short .read_root_dir
	
	jmp .error
.root_dir_done:
	cmp al, 14 ; Check that all sectors have been read
	jne .error

	mov cx, word [root_dir_entries]
	mov bx, -32
	mov ax, ds
	mov es, ax
.find_root_entry:
	add bx, 32
	mov di, _DBUFF_
	
	add di, bx
	
	cmp byte [di], 000h
	je short .skip_entry
	
	cmp byte [di], 0E5h
	je short .skip_entry
	
	cmp byte [di+11], 0Fh
	je short .skip_entry
	
	cmp byte [di+11], 08h
	je short .skip_entry
	
	cmp byte [di+11], 00111111b
	je short .skip_entry
	
	xchg dx, cx

	mov cx, 11 ; Compare filename with entry
	mov si, [.filename]
	rep cmpsb
	je short .file_found
	
	xchg dx, cx
	
.skip_entry:
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
	push dx
	cli
	
	stc
	int 13h
	
	sti
	pop dx
	
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
	
	push dx
	cli
	
	stc
	int 13h
	
	sti
	pop dx
	
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
	
	;push ax
	;mov ax, [bytes_per_sector]
	add word [.offs], 512 ; Set correct BPS
	;pop ax
	
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
	
print_fat12:
	push bp
	push si
	push ax
	push bx
	push cx
	
	mov ah, 0Eh
	mov cx, 11
	xor bh, bh
.loop:
	lodsb
	
	int 10h
	
	loop .loop
.end:
	pop cx
	pop bx
	pop ax
	pop si
	pop bp
	ret
	
strfat12:
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
	
print:
	push si
	push ax
	
	mov ah, 0Eh
.loop:
	lodsb
	
	test al, al
	jz short .end
	
	int 10h
	
	jmp short .loop
.end:
	pop ax
	pop si
	ret
	
; Variables used for device detection
serialAddr_1		dw 0
serialAddr_2		dw 0
serialAddr_3		dw 0
serialAddr_4		dw 0
parallelAddr_1		dw 0
parallelAddr_2		dw 0
parallelAddr_3		dw 0

; Device detected are stored here
videoMainSrc		db 0
serials				db 0
parallels			db 0

; Devices varnames
serialDev_1			db "serial1"
serialDev_2			db "serial2"
serialDev_3			db "serial3"
serialDev_4			db "serial4"
parallelDev_1		db "para1"
parallelDev_2		db "para2"
parallelDev_3		db "para3"
vgaDev				db "vga"
egaDev				db "ega"
mdaDev				db "mda"
cgaDev				db "cga"
