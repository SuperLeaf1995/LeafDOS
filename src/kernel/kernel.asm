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

; This functions are used by programs
jmp dummy
jmp call_lib
jmp run_program
jmp load_file
jmp alloc
jmp free

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
	
	; Create a free block of memory!
	push di
	mov di, 2000h
	mov byte [di+00h], 01h
	mov word [di+01h], 0FFFh ; Set size to take an entire segment (minus ome stuff)
	mov word [di+03h], 0B00h ; Start after kernel and _DBUF_
	mov word [di+05h], 0000h ; Set the segment as our kernel segment!
	mov byte [di+07h], 00h ; Set EOF for memtable
	pop di
	
	mov ax, 5000h
	mov si, mod_lib
	call load_file
	jc .error
	
	mov si, mod_comm
	call run_program
	jc .error
.error:
	jmp $

mod_lib		db "IO      LIB"
mod_comm	db "COMMAND COM"
error_mem	db "Not engough memory!",0Dh,0Ah,0

dummy:
	mov ah, 0Eh
	mov al, '?'
	int 10h
	jmp short dummy

;
; Calls a function from a dynamically linked library (DLL)
; in LeafDOS
;
; SI: Name of function to search
; CF: Clear on error
;
call_lib:
	push ax
	push bx
	push cx
	push di
	
	mov di, 5000h ; Libraries load at 5000h
.find_function:
	call strlen
	
	rep cmpsb
	je short .found_function
	
	jmp short .find_function
.found_function:
	add si, cx ; Skip the name of function
	; After the name of the function the jump vector comes in!
	mov ax, si
	call ax ; Call the function
	
	stc ; Set the carry
.end:
	pop di
	pop cx
	pop bx
	pop ax
	ret
	
.error:
	clc
	jmp short .end

;
; Gets lenght of a string in SI, returns CX
;
strlen:
	push ax
	push si
.loop:
	lodsb
	inc cx
	
	test al, al
	jnz short .loop
.end:
	dec cx
	
	pop si
	pop ax
	ret

;
; Allocates memory with the size of (BX)
; Returns pointer in (AX), CF clear on error
;
; For future reference, this is the structure of a
; memtable entry:
;
; byte Status
;	00h : No block (invalid memory block/end of memtable)
;	01h : Free entry
;	02h : Used entry
; word Size
; word StartOffset
; word Segment
;
; * In total, each entry is 6 bytes long!
; ** Regardless of segments, all memory blocks are treated as if they where
; on a single segment
;
alloc:
	push bx
	push di
	
	mov di, 02000h-6 ; Point at the memtable (-6)
.find_free:
	add di, 6

	cmp byte [di], 00h ; Empty entry (end of memtable)
	je .no_free
	
	cmp byte [di], 01h ; Free entry!
	je .check_free
	
	jmp short .find_free
;
; Checks that memory region is big engough for allocation
;
.check_free:
	cmp word [di+01h], bx ; Is block big engough?
	jl short .find_free ; If it is not, go back and find more blocks!
	
; Else...
;
; Splits a free memory block entry into a "used" and "free" part
;
.split_free_block:
	; Shrink free block
	mov ax, word [di+01h]
	sub ax, bx ; Remove "used" part
	mov word [di+01h], ax ; Set new value
	; StartingOffset grows (used block takes first part of free block)
	mov ax, word [di+03h]
	push ax ; Save AX (for usage in the new "used" entry)
	add ax, bx ; This also shrinks the block
	mov word [di+03h], ax ; Set the new value
	
	; Set the new "used" block
	add di, 6
	mov byte [di], 02h ; Mark block as "used"
	mov word [di+01h], bx ; Size of block is in entry now!
	pop ax ; Now set the StartingOffset
	mov word [di+03h], ax ; Set the StartingOffset
	mov word [di+05h], ds ; Set the segment of "used" block
	
	stc
.end:
	pop di ; Restore registers
	pop bx
	ret ; Finally return
;
; No allocable block found, return CF
;
.no_free:
	clc
	jmp short .end

;
; Frees memory (TODO: Merge free blocks)
;
; AX: Pointer of memory
; BX: Segment
; Returns clear Carry Flag on error
free:
	push ax
	push bx
	push cx
	push di
	push es

	mov di, 02000h-6
;
;First, let's find the block wich has AX and BX
;
.find_block:
	add di, 6 ; Skip one full entry

	cmp [di+03h], ax ; If pointer is the same lets try to find if same segment too
	je short .is_same_segment

	cmp byte [di+00h], 00h ; End of memtable?
	je .no_free
	
	jmp short .find_block
;
; Check validity (is it of the same segment?)
;
.is_same_segment:
	cmp word [di+05h], bx ; Is it the same segment?
	jne short .find_block
	
	; Now it's time to set it as "free" instead of used
	mov byte [di+00h], 01h ; 01h = Free block

	stc
;
; We are done!
;
.end:
	pop es
	pop di
	pop cx
	pop bx
	pop ax
	ret
	
.no_free:
	clc
	jmp short .end

;
; Runs a program.
; As of now it can only load .COM files
;
run_program:
	push ax
	push bx

	mov bx, 4096 ; Allocate 4096 Bytes for our file
	call alloc
	jc .error
	
	push ax
	
	mov ax, 0A00h
	mov es, ax
	mov ax, 0100h
	call load_file
	jc .error
	
	clc ; Set carry flag to clear
.load_com:
	; TODO: Dynamically load programs
	; Write PSP for the COM file
	xor di, di
	mov word [es:di+00h], 0CD22h
	
	mov ax, 0A00h ; Set the segments for the .COM file
	mov ds, ax
	mov es, ax ; Set ES to segment of DS
	
	call 0A00h:0100h ; Load COM file
	
	xor ax, ax ; Set back our segments
	mov ds, ax
	mov es, ax
	
	jmp short .end
.error:
	stc
.end:
	pop ax ; Free the used memory for the program
	
	call free
	jc .error
	
	pop bx
	pop ax
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
