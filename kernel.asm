BITS 16

DiskBuffer equ 24576

StartKernel:
	cli
	mov ax, 0
	mov ss, ax
	mov sp, 0x0FFFF
	sti
	cld ;Go UP in the RAM
	mov ax, 0x2000
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	;Save device number
	mov [FloppyDevice.Number], dl
	;Set cursor position to 0
	xor dh, dh
	xor dl, dl
	call SetCursorPosition
	mov si, WelcomeMessage
	call PrintText
	;mov cx, 32
	;mov dl, 16
	;mov di, IntTest
	;call IntegerToString
	;mov si, IntTest
	;call PrintText
	mov di, KeyboardBuffer
	
InfiniteLoop:
	call KeyboardInput
	call FlushKeyboardBuffer
	jmp InfiniteLoop ; Loop forever
	
;In: SI = String, BL = Colour
;Out: CX = Lenght of the string
global PrintText
PrintText:
	xor cx, cx
	jmp .loop
.loop:
	lodsb
	mov ah, 0x0E
	cmp al, 0x0
	je .end
	cmp al, 0xD
	je .newline
	cmp al, 0x9
	je .tab
	int 0x10
	inc cx
	jmp .loop
.newline:
	call GetCursorPosition
	mov dl, 0
	mov dh, [TextCursorY]
	inc dh
	call SetCursorPosition
.tab:
	call GetCursorPosition
	mov dl, [TextCursorX]
	add dl, 4
	mov dh, [TextCursorY]
	call SetCursorPosition
.end:
	ret
	
;In: Nothing
;Out: CH = Start scanline, CL = End scanline, DH = row, DL = Column
global GetCursorPosition
GetCursorPosition:
	mov ah, 0x03
	int 0x10
	mov [TextCursorX], dl
	mov [TextCursorY], dh
	ret
	
;In: DH = Row, DL = Column
;Out: Nothing
global SetCursorPosition
SetCursorPosition:
	; Save positions
	mov [TextCursorX], dl
	mov [TextCursorY], dh
	mov ah ,0x2
	int 0x10
	ret
	
Reboot:
	xor ax, ax
	int 0x19
	ret
	
;In: Nothing
;Out: AH = BIOS scan code, AL = ASCII character
global KeyStroke
KeyStroke:
	mov ah, 0x0
	int 0x16
	ret
	
;In: Nothing
;Out: AH = BIOS scan code, AL = ASCII character
global KeyboardInput
KeyboardInput:
	;Reset CX
	xor cx, cx
.loop:
	mov ah, 0x0
	int 0x16
	;Special keys
	cmp al, 0xD
	je .end
	cmp al, 0x8
	je .back
	cmp cx, 0xFE
	jge .end
	mov ah, 0x0E
	int 0x10
	inc cx
	jmp .loop
.back:
	cmp cx, 0x0
	je .loop
	dec di
	mov byte [di], 0
	dec cx
	mov ah, 0x0E
	mov al, 0x08
	int 0x10
	mov al, 0x20
	int 0x10
	mov al, 0x08
	int 0x10
	jmp .loop
.end:
	call GetCursorPosition
	mov dl, 0
	mov dh, [TextCursorY]
	inc dh
	call SetCursorPosition
	mov al, 0
	stosb
	ret
	
;In: Nothing
;Out: Nothing
global FlushKeyboardBuffer
FlushKeyboardBuffer:
	mov di, 0xFE
	mov cx, 0xFE
.loop:
	cmp cx, 0
	je .end
	dec cx
	dec di
	mov al, 0
	stosb
	jmp .loop
.end:
	ret
	
;In: FloppyDevice
;Out: AH = Status, CF = Flag
global ResetFloppyDisk
ResetFloppyDisk:
	push ax
	mov ah, 0x00
	mov dl, [FloppyDevice]
	int 0x13
	pop ax
	ret
	
;In: CX = Number, DI = Returning String, DL = Base
;Out: Nothing
global IntegerToString
IntegerToString:
	cmp cx, 0
	je .zero
.nonzero:
	cmp cx, 0 ;Is CX zero?
	jle .end
	
	mov ax, cx
	div dl ;Divide AX(cx)/DL (num/base)
	
	cmp ah, 10
	jge .greater
	
	add ah, '0'

	mov cl, al
	mov al, ah
	stosb
	jmp .nonzero
.greater:
	sub ah, 10
	add ah, 'A'
	mov al, ah
	stosb
	jmp .nonzero
.zero:
	mov al, '0' ;Integer zero
	stosb
.end:
	mov al, 0 ;Null terminator
	stosb
	ret

;In: SI = String
;Out: CX = Lenght
global StringLenght
StringLenght:
	xor cx, cx
.loop:
	lodsb
	cmp al, 0
	je .end
	inc cx
	jmp .loop
.end:
	ret
	
;In: DL = Drive
;Out: FloppyDevice struct
global GetDriveParams
GetDriveParams:
	mov ah, 0x08
	mov [es:di], 0x0000:0x0000 ;Guard against BIOS bugs
	cmp dl, 0
	je .Skip
	int 0x13
	jnc .FatalError
	and cx, 3Fh ;Max sector number
	mov [FloppyDevice.SectorsPerTrack], cx ;Why it starts at 1?, those are confusing times
	movzx dx, dh
	add dx, 1
	mov [FloppyDevice.Heads], dx
.Skip:
	mov eax, 0
	ret
.FatalError:
	mov si, ErrorDriveParameters
	call PrintText
	ret

;In: Nothing
;Out: Nothing
	
;Data
TextCursorY						db 0
TextCursorX						db 0

;(512 bytes/sector)×(18 sectors/track)×(2 heads (tracks/cylinder))

FloppyDevice:
	.Number						db 0
	.BytesPerSector				dw 512
	.SectorsPerCluster			db 1
	.NumberOfFAT				db 2
	.RootDirEntries				dw 224
	.SectorsPerFAT				dw 9
	.SectorsPerTrack			dw 18
	.Cylinders					db 0
	.Heads						db 2

;Strings
WelcomeMessage					db 'LeafOS 0.5',0xD,0

ErrorDriveParameters			db 'Error: Cannot get drive parameters',0xD,0

;Other data
NewlineAndNull					db 0xD,0x0
KeyboardBuffer 					times 256 db 0
IntTest							times 16 db 0