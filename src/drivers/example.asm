;  EXAMPLE.ASM
;
;  Example LeafDOS driver
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are
;  met:
;  
;  * Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
;  * Redistributions in binary form must reproduce the above
;    copyright notice, this list of conditions and the following disclaimer
;    in the documentation and/or other materials provided with the
;    distribution.
;  * Neither the name of the  nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;  
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;  

use16
cpu 8086
org 7000h

;
; Driver header
;
; Common Driver Jumptable
; All LeafDOS drivers has atleast one, must be 90 bytes in size.
;
commonDriverJumptable:
	jmp start			; Used when driver is loaded as a program
	jmp func			; Set carry
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved

;
; Common Driver Metadata
; Useful data for driver-loaders
;
commonDriverMetadata:
	versionMajor		db 1 ; Major version of the driver
	versionMinor		db 2 ; Minor version of the driver (i.e a patch)
	versionBuild		db 2 ; Build version (Can be safely ignored)
	name				db "VIDEO_DS" ; Name of the driver, must be
									  ; 8 bytes long
	reserved			db 0 ; Reserved (commonly used as NULL terminator)
	
	osVersion			db 1 ; Version in wich it was compiled for
							 ; Driver managers have to always check this value
							 ; If it its higher than current LDOS version
							 ; The driver can not work properly
							 ; Version ID's
							 ; 01h - 0.2.6
	checksum			dw 6969h ; Magic number (Driver managers always
								 ; needs to check that this value is correct)
	deviceType			dw 0000h ; Device type
								 ; 0000h - Video
								 ; 0001h - Sound
								 ; 0002h - Keyboard
								 ; 0003h - Mouse
								 ; 0004h - Joystick
								 ; 0005h - Serial Port
								 ; 0006h - Network
								 ; 0007h - Filesystem Driver
	reserved			times 32 db 0
						 
start:
	ret
	
stub:
	clc
	ret
	
func:
	stc
	ret
