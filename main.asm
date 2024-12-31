section .data
	; camera position
	cam_x: db 0
	cam_y: db 0
	cam_z: db 0

	; sphere position
	sp_x: db 0
	sp_y: db 0
	sp_z: db 0

	; looping
	count: db 0

	; screen size
	sc_col: dw 0
	sc_row: dw 0

	whmsg db 'Screen width: %u  Screen height: %u', 10, 0

	lpmsg db 'looped', 0

section .bss
	sz RESW 4
	ray_pointers RESQ 1

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

	mov rdi, whmsg ; print screen size using printf
	movzx rsi, WORD [sc_col]
	movzx rdx, WORD [sc_row]
	xor eax, eax
	call printf

	mov rdi, [sc_col] ; malloc screen cols to ray pointers
	call malloc
	mov [ray_pointers], rax

	; initialize row loop
	movzx eax, WORD [sc_row]
	mov [count], al

allocate_ray_rows:

	
	mov rdi, lpmsg ; print screen size using printf
	xor eax, eax
	call printf

	dec BYTE [count]	
	cmp BYTE [count], 0
	jg allocate_ray_rows

	xor edi, edi
	call exit
