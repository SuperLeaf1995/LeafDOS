.section .init
.global _init
_init:
	push %ebp
	movl %esp, ebp
	
.section .fini
.global _fini
_fini:
	push %ebp
	movl %esp, %ebp
