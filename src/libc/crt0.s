.section .text
.global _start
_start:
	movl $0, %ebp
	pushl %ebp
	pushl %ebp
	movl %esp
	
	pushl %esi
	pushl %edi
	
	call _init_stdlib
	call _init
	
	popl %edi
	popl %esi
	
	call main
	
	movl %eax, %edi
	call exit
.size _start, . - _start

	# Run main
	call main

	# Terminate the process with the exit code.
	movl %eax, %edi
	call exit
.size _start, . - _start
