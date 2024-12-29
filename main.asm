section .data
	; camera position
	cam_x: db 0
	cam_y: db 0
	cam_z: db 0

	; sphere position
	sp_x: db 0
	sp_y: db 0
	sp_z: db 0

	fmt db `Screen width: %u  Screen height: %u\n`,0

section .bss
	sz RESW 4

section .text
global _start
extern printf, exit

_start:

	mov eax,16
	mov edi, 1
	mov esi, 0x5413
	mov edx, sz
	syscall

	mov rdi, fmt
	movzx rsi, WORD [sz+2]
	movzx rdx, WORD [sz+0]
	xor eax, eax
	call printf

	xor edi, edi
	call exit
