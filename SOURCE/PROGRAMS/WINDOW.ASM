;WINDOW.ASM
;Windows 95-alike GUI for LeafDOS

%define __sdef_program__
%include "..\io.inc" ;include the entire kernel api
	
istruc file
	at	f_name,			db 'window'
	at	f_extension,	db 'com'
iend

_main:
	mov si, start_msg
	call io_display_print_text
	
	mov si, press_key
	call io_display_print_text
	call io_keyboard_keypress
	
	;save old video mode for when we close the program
	call io_display_get_current_video_mode
	mov byte [old_video], al ;save old video
	
	;set a nice VGA display
	mov al, 13h
	call io_display_set_video_mode
	
	;now that we are with the vga thing is time to set up some stuff...
	
	;todo: set drivers and many shit
	
_main_loop:
	call _fill_blue
	
_end:
	mov al, byte [old_video] ;get old video back to our hands!
	call io_display_set_video_mode ;set it
	
	mov si, end_msg ;now we happily say goodbye world
	call io_display_print_text
	mov si, press_key
	call io_display_print_text
	call io_keyboard_keypress
	ret ;end
	
_fill_blue:
;	mov ax, 320 ;wide n tall
;	mov bx, 200 ;stuff...
;	mul bx ;ax*bx = total size of stuff to fill
;	
;	mov cx, ax ;save in cx
;	
;	xor ax, ax
;	xor bx, bx
;.loop:
;	inc ax
;	mov dl, 01h
;	call io_display_print_pixel
;	
;	loop .loop ;dec cx, and welp, ret if cx = 0
	xor ax, ax
	xor bx, bx
.loop:
	inc ax
	mov dl, 20h
	call io_display_print_pixel
	
	cmp ax, 64000
	jne .loop
	ret

start_msg	db 'WINDOW.COM is starting... Hello world!',__newline__,0
end_msg		db 'WINDOW.COM is closing... Goodbye world!',__newline__,0
press_key	db 'press any key to continue...',__newline__,0

old_video	db 0
