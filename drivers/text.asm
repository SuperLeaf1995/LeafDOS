global print_text
print_text:
  mov ax, 0x0E
  lodsb
  cmp al, 0
  je .end
  int 0x10
  jmp print_text
.end:
  ret
