global key_press
get_press:
  mov ah, 0x00
  int 0x16
  ret
  
global keyboard_input
keyboard_input:
  xor cl, cl
  jmp .loop
.loop:
  mov ah, 0x00
  int 0x16
  
  ; It would return AL, lets handle it!
  cmp al, 0x0D
  je .end
  cmp cl, 0x20
  je .loop
  
  mov ah, 0x0E
  int 0x10
.end:
  ret
