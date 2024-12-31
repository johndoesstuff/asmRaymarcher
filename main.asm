section .data
	; camera position
	cam_pos: dq 0.0, 0.0, 0.0

	; sphere position
	sp_pos: dq 0.0, 0.0, 0.0

	; looping
	current_row: dw 0
	current_col: dw 0

	ray_pos: db 0.0, 0.0, 0.0
	ray_dir: db 0.0, 0.0, 0.0

	; screen size
	sc_col: dw 0
	sc_row: dw 0

	whmsg db 'Screen width: %u  Screen height: %u', 10, 0

	shading db '.', 0

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

	; initialize row loop
	mov ax, WORD [sc_row]
	mov [current_row], ax

do_row:
	
	; initialize col loop
	mov ax, WORD [sc_col]
	mov [current_col], ax

	call do_col
	
	dec WORD [current_row] ; dec row counter
	cmp WORD [current_row], 0
	ja do_row

	xor edi, edi
	call exit

do_col:
	
	call cast_ray

	mov rdi, shading
	xor eax, eax
	call printf

	dec WORD [current_col] ; dec col counter
	cmp WORD [current_col], 0
	ja do_col

	ret

cast_ray:

	
	
	ret
