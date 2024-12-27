section	.text
	global _start
	
_start:
	mov	edx, shadingslen
	mov	ecx, shadings
	mov	ebx, 1
	mov	eax, 4
	int	0x80
	
	mov	eax, 1
	int	0x80

section	.data
	shadings db ' .+#+. ', 0xa
	shadingslen equ $ - shadings
