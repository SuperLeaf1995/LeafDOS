; Input: AL = Video mode
; Return: AL = Flags
global set_video_mode
set_video_mode:
  mov ah, 0x00
  int 0x10
  ret
  
; Output: AL = Video mode, AH = Columns
global get_video_mode
get_video_mode:
  mov ah, 0x0F
  int 0x10
  ret
