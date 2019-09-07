; Use the -i option in NASM
%include "drivers/text.asm"
  ;segment * 16 + offset = address
  mov ax, 0x07C0
  mov ds, ax
  cli ; Flush registers and stuff, basicaly we are all clear
  ; A welcoming message
  mov si, boot_msg1
  call print_text
boot:
  jmp $ ; Loop forever
  
  ; Okey, we are now safe, lets do something more
  boot_msg1 db 'Bootloading',0
  times 510-($-$$) db 0
  db 0x55 0xAA ; IBM Floppy Signature
