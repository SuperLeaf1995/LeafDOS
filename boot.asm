; Use the -i option in NASM
%include "drivers/text.asm"
%include "drivers/key.asm"
[ORG 0x7C00]
[BITS 16] ; We want 16 bits, deal with it
  xor ax, ax
  
  ;segment * 16 + offset = address
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00
  cli ; Flush registers and stuff, basicaly we are all clear
  
  ; A welcoming message
  mov si, boot_msg1
  call print_text
  
  jmp boot
boot:
  jmp $ ; Loop forever
  
  ; Okey, we are now safe, lets do something more
  boot_msg1 db 'Bootloading',0
  times 510-($-$$) db 0
  db 0x55 0xAA ; IBM Floppy Signature
