section .data
	; camera position
	cam_x: db 0
	cam_y: db 0
	cam_z: db 0

	; sphere position
	sp_x: db 0
	sp_y: db 0
	sp_z: db 0

	sc_col: dw 0
	sc_row: dw 0

	fmt db 'Screen width: %u  Screen height: %u', 10, 0

section .bss
	sz RESW 4

section .text
global _start
extern printf, exit, malloc

_start:

	mov eax, 16 ; sys_ioctl call
	mov edi, 1
	mov esi, 0x5413
	mov edx, sz
	syscall

	movzx rsi, WORD [sz+2]
	movzx rdi, WORD [sz+0]

	mov WORD [sc_col], si
	mov WORD [sc_row], di

	mov rdi, fmt ; print screen size using printf
	movzx rsi, WORD [sc_col]
	movzx rdx, WORD [sc_row]
	xor eax, eax
	call printf

	mov rdi, [sc_col] ; malloc screen cols
	call malloc

	mov rbx, rax

	xor edi, edi
	call exit
