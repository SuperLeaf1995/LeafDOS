; Use the -i option in NASM
%include "drivers/text.asm"

  cli ; Flush registers and stuff, basicaly we are all clear
boot:
  jmp $ ; Loop forever
  
  times 510-($-$$) db 0
  db 0x55 0xAA ; IBM Floppy Signature
