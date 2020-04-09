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
org 1000h ; Special kernel program

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
	
	call 0506h
	
	mov si, autorun
	mov di, tmpbuf
	call strfat12

	mov si, di
	mov ax, 1FFFh
	call 0503h
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
