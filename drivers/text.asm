; Input SI = String, BL = color
global print_text
print_text:
  mov ah, 0x0E
  lodsb
  cmp al, 0
  je .end
  int 0x10
  jmp print_text
.end:
  ret

; Input DH = X, DX = Y
global gotoxy
gotoxy:
  cmp dh, 0 ; Like DOS, allow non-zero values
  je .end
  cmp dx, 0
  je .end
  mov ah, 0x02
  int 0x10
  jmp .end
.end:
  ret
