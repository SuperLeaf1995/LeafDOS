BITS 16

DiskBuffer equ 24576

StartKernel:
	cli
	mov ax, 0
	mov ss, ax
	mov sp, 0x0FFFF
	sti
	cld ;Go UP in the RAM
	mov ax, 8192
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	;Save device number
	mov [FloppyDevice.Drive], dl
	
	;Start of KERNEL.BIN functions
	;Set cursor position to 0
	xor dh, dh
	xor dl, dl
	call SetCursorPosition
	
	;Clear Screen, BOCHS adds some text we dont want, we must delete it!-
	;Assume its 80*25
	mov al, ' '
	mov ah, 0x0E
	xor cx, cx
.loop:
	int 0x10
	inc cx
	cmp cx, 2000 ;Total characters in Text mode
	jne .loop
	
	;Set cursor position to 0, AGAIN
	xor dh, dh
	xor dl, dl
	call SetCursorPosition

	mov si, WelcomeMessage
	call PrintText
	
InfiniteLoop:
	;Put the drive letter and pad the thing
	mov al, [FloppyDevice.Drive]
	add al, 'A' ;A + Drive number (either A or B)
	call PrintChar
	mov si, DriveLetterPadding
	call PrintText ;Display letter pad before the buffer, AKA. MS-DOS feel
	
	mov di, KeyboardBuffer
	call KeyboardInput
	
	mov di, CommandTest
	mov si, KeyboardBuffer
	call StringCompare
	jc .CMDTest
	
	jmp InfiniteLoop ; Loop forever
	
;=========================================================
;KERNEL-SPECIFIC SUBROUTINES
;=========================================================

.CMDTest:
	mov si, CommandTestReply
	call PrintText
	jmp InfiniteLoop
	
;=========================================================
;VIDEO-TEXT ROUTINES
;=========================================================
	
;In: AL = Char, BL = Colour
;Out: Nothing
global PrintChar
PrintChar:
	mov ah, 0x0E
	int 0x10
	ret
	
;In: SI = String, BL = Colour
;Out: CX = Lenght of the string
global PrintText
PrintText:
	push ax ;Save ax, we may need it
	
	xor cx, cx
	jmp .loop
.loop:
	lodsb
	mov ah, 0x0E
	
	cmp al, 0x0 ;We have 0x0, how? Well, we dont know, but we must end
	je .end
	cmp al, 0xD ;A newline
	je .newline
	cmp al, 0x9 ;Tab, add 4 spaces
	je .tab
	int 0x10 ;Int 10h, wow

	inc cx
	
	jmp .loop
.newline:
	call GetCursorPosition
	mov dl, 0
	mov dh, [TextCursorY]
	inc dh ;Current Y + 1
	call SetCursorPosition
	jmp .loop
.tab:
	call GetCursorPosition
	mov dl, [TextCursorX]
	add dl, 4 ;Add 4 to the current x (X+4) is liek a tab, ok?
	mov dh, [TextCursorY]
	call SetCursorPosition
	jmp .loop
.end:
	pop ax
	ret
	
;=========================================================
;KEYBOARD ROUTINES
;=========================================================
	
;In: Nothing
;Out: AH = BIOS scan code, AL = ASCII character
global KeyStroke
KeyStroke:
	mov ah, 0x0
	int 0x16
	ret
	
;In: Nothing
;Out: DI = Address of keyboard buffer
global KeyboardInput
KeyboardInput:
	xor cx, cx ;Set CX to zero
.loop:
	mov ah, 0x0
	int 0x16
	
	;Special keys
	cmp al, 0xD ;Newline = End
	je .end
	cmp al, 0x8 ;Backspace
	je .back
	cmp cx, 0x1F ;32 chars? oh well, lets go off
	jge .end
	
	mov ah, 0x0E
	int 0x10
	inc cx
	
	stosb
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
	
;=========================================================
;TEXT CURSOR ROUTINES
;=========================================================
	
;In: Nothing
;Out: CH = Start scanline, CL = End scanline, DH = row, DL = Column
global GetCursorPosition
GetCursorPosition:
	push ax
	mov ah, 0x03
	int 0x10
	mov [TextCursorX], dl
	mov [TextCursorY], dh
	pop ax
	ret
	
;In: DH = Row, DL = Column
;Out: Nothing
global SetCursorPosition
SetCursorPosition:
	;Save positions
	push ax
	mov ah ,0x2
	int 0x10
	pop ax
	ret
	
;In: CH = Scan row, CL = Scan row part 2: electric boogaloo
;Out: Nothing
global SetCursorShape
SetCursorShape:
	push ax
	mov ah, 0x1
	int 0x10
	pop ax
	ret
	
;=========================================================
;CONVERSION ROUTINES
;=========================================================
	
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
	
;=========================================================
;STRING MANAGEMENT ROUTINES
;=========================================================
	
;In: SI = String 1, DI = String 2
;Out: CF = Clear if NOT equal
global StringCompare
StringCompare:
.loop:
	mov al, [si]
	mov bl, [di]
	
	cmp al, bl
	jne .notequal
	cmp al, 32
	jl .equal
	
	cmp bl, 32
	jl .equal
	
	inc si
	inc di
	jmp .loop
.notequal:
	clc
	mov si, ErrorDiskReset
	call PrintText
	ret
.equal:
	stc
	mov si, WelcomeMessage
	call PrintText
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
	
global ToUppercase
ToUppercase:
.loop:
	lodsb
	cmp al, 0
	je .end
	cmp al, 'a' ;We got a letter A
	jge .ToUpper
.ToUpper:
	;Is it below the standard A?
	cmp al, 'a'
	jl .loop
	;Yay we found an A
	sub al, 76
	stosb ;We uppercase it
.end:
	ret
	
;=========================================================
;MISCELLANEOUS ROUTINES
;=========================================================
	
global Reboot
Reboot:
	xor ax, ax
	int 0x19
	ret
	
;=========================================================
;DISK ROUTINES ANYTHING AFTER THIS SHOULDT BE USED
;=========================================================

;In: Nothing
;Out: Nothing

;=========================================================
;DATA
;=========================================================
	
;Data
TextCursorY						db 0
TextCursorX						db 0

;(512 bytes/sector)×(18 sectors/track)×(2 heads (tracks/cylinder))
FloppyDevice:
	.BytesPerSector				dw 512
	.SectorsPerCluster			db 1
	.NumberOfFAT				db 2
	.RootDirEntries				dw 224
	.SectorsPerFAT				dw 9
	.SectorsPerTrack			dw 18
	.Cylinders					dw 80
	.Heads						dw 2
	.HeadsPerCluster			dw 1
	.Drive						db 0

;Boot Messages (Kernel loaded, now fetching data and displaying it)
WelcomeMessage					db 'LeafOS 1.0',0xD,0

DriveLetterPadding				db ':\>',0

;Errors... Sad errors
ErrorDiskReset					db 'Disk Reset Fatal Error',0x0D,0

;CMDS
CommandTest						db 'Ping',0x0D,0

;"Reply" commands
CommandTestReply				db 'Pong',0x0D,0

;Other data
KeyboardBuffer 					times 0x21 db 0
TextTempBuffer					times 0xFF db 0