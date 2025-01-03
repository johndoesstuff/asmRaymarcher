section .data
	; camera position
	cam_pos: dq 0.0, 0.0, 0.0

	; sphere position
	sp_pos: dq 0.0, 0.0, 0.0

	; looping
	current_row: dw 0
	current_col: dw 0

	; screen size
	sc_col: dw 0
	sc_row: dw 0

	; float screen size
	sc_colf: dd 0.0
	sc_rowf: dd 0.0

	zero: dd 0.0
	one: dd 1.0
	half: dd 0.5
	two: dd 2.0

	whmsg db 'Screen width: %u  Screen height: %u', 10, 0

	shading db '.', 0

	ray_debug db '%f,%f,%f', 10, 0

section .bss
	sz resw 4

	; ray stuff
	ray_pos resd 3
	ray_dir resd 3

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

	; get float screen size
	movzx eax, WORD [sc_col]
	cvtsi2ss xmm0, eax
	movss [sc_colf], xmm0
	movzx eax, WORD [sc_row]
	cvtsi2ss xmm0, eax
	movss [sc_rowf], xmm0

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

	movzx eax, WORD [current_col]
	cvtsi2ss xmm0, eax ; convert col to float
	movss [ray_dir], xmm0 ; store col

	movzx eax, WORD [current_row]
	cvtsi2ss xmm0, eax
	movss [ray_dir+4], xmm0 ; store row

	movss xmm0, [one]
	movss [ray_dir+8], xmm0

	; align ray direction
	movss xmm1, [sc_colf] ; align col
	movss xmm0, [ray_dir]
	mulss xmm1, [half] ; divide col by 2
	subss xmm0, xmm1 ; c-col/2
	mulss xmm0, [two] ; 2*(c-col/2)
	divss xmm0, [sc_colf]
	movss [ray_dir], xmm0

	movss xmm1, [sc_rowf] ; align row
	movss xmm0, [ray_dir+4]
	mulss xmm1, [half] ; divide row by 2
	subss xmm0, xmm1 ; r-row/2
	mulss xmm0, [two] ; 2*(r-row/2)
	divss xmm0, [sc_rowf]
	movss [ray_dir+4], xmm0

	; normalize ray
	movss xmm0, [ray_dir]
	mulss xmm0, xmm0
	movss xmm1, [ray_dir+4]
	mulss xmm1, xmm1
	addss xmm0, xmm1
	movss xmm1, [ray_dir+8]
	mulss xmm1, xmm1
	addss xmm0, xmm1

	sqrtss xmm0, xmm0

	movss xmm1, [ray_dir]
	divss xmm1, xmm0
	movss [ray_dir], xmm1

	movss xmm1, [ray_dir+4]
	divss xmm1, xmm0
	movss [ray_dir+4], xmm1

	movss xmm1, [ray_dir+8]
	divss xmm1, xmm0
	movss [ray_dir+8], xmm1

	movss xmm0, [cam_pos]
	movss [ray_pos], xmm0
	movss xmm0, [cam_pos+8]
	movss [ray_pos+4], xmm0
	movss xmm9, [cam_pos+16]
	movss [ray_pos+8], xmm0

	; debug
	movss xmm0, [ray_dir]
	movss xmm1, [ray_dir+4]
	movss xmm2, [ray_dir+8]
	cvtss2sd xmm0, xmm0 ; convert to double for printf
	cvtss2sd xmm1, xmm1 ; convert to double for printf
	cvtss2sd xmm2, xmm2 ; convert to double for printf
        lea rdi, [ray_debug]
	mov eax, 3
        call printf

	ret
