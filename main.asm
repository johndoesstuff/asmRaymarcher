section .data
	; camera position
	cam_pos: dd 0.0, 0.0, 0

	; sphere position
	sp_pos: dd 7.5, 7.5, 7.5
	sp_rad: dd 5.0

	; ray distance
	ray_dst: dd 0.0

	; iterations
	iterations: dw 50
	i_count: dw 0

	; space wrap
	space_wrap: dd 15.0

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

	epsilon: dd 0.001

	shading_max: dd 6.0

	shading_min: dd 1.0

	whmsg db 'Screen width: %u  Screen height: %u', 10, 0

	;shading db '.', 0

	ray_debug db '%f,%f,%f', 10, 0

	sdf_debug db 'sdf: %f', 10, 0

	shading db ' #x*+-.'
	shadingf db '%c', 0

	shading_debug db 'ray_dst: %f', 10, 0

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

	;mov rdi, shading
	;xor eax, eax
	;call printf

	dec WORD [current_col] ; dec col counter
	cmp WORD [current_col], 0
	ja do_col

	ret

cast_ray:

	movss xmm0, [zero] ; reset ray_dst
	movss [ray_dst], xmm0
	
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

	movss xmm0, [cam_pos] ; initialize ray to camera
	movss [ray_pos], xmm0
	movss xmm0, [cam_pos+4]
	movss [ray_pos+4], xmm0
	movss xmm0, [cam_pos+8]
	movss [ray_pos+8], xmm0
	
	mov WORD [i_count], 0

march_ray_loop:

	call march_ray
	inc WORD [i_count]
	movzx eax, WORD [iterations]
	cmp WORD [i_count], ax
	jb march_ray_loop

	call get_sdf

	ucomiss xmm0, [epsilon] ; check for hit
	jb ray_hit
	jnb ray_nothit

ray_hit:

	movss xmm0, [ray_dst]
	divss xmm0, [two]
	divss xmm0, [two]
	divss xmm0, [two]
	minss xmm0, [shading_max]
	maxss xmm0, [shading_min]
	xor rax, rax
	cvttss2si eax, xmm0
	mov rcx, rax
	
	;mov rcx, 5
	jmp shade_ray

ray_nothit:

	mov rcx, 0
	jmp shade_ray

shade_ray:

	; index shading by rcx
	mov rdi, shadingf
	xor eax, eax
	mov rsi, shading
	add rsi, rcx
	mov al, byte [rsi]
	movzx rsi, al
	call printf
	
	; debug
	movss xmm0, [ray_pos]
	movss xmm1, [ray_pos+4]
	movss xmm2, [ray_pos+8]
	cvtss2sd xmm0, xmm0 ; convert to double for printf
	cvtss2sd xmm1, xmm1 ; convert to double for printf
	cvtss2sd xmm2, xmm2 ; convert to double for printf
        lea rdi, [ray_debug]
	mov eax, 3
        ;call printf

	call get_sdf
	cvtss2sd xmm0, xmm0
	lea rdi, [sdf_debug]
	mov eax, 1
	;call printf

	ret

march_ray:

	call get_sdf
	movss xmm1, [ray_dst]
	addss xmm1, xmm0
	movss [ray_dst], xmm1 ; acc ray_dst
	
	movss xmm1, [ray_dir] ; load ray_dir
	movss xmm2, [ray_dir+4]
	movss xmm3, [ray_dir+8]

	mulss xmm1, xmm0 ; multiply ray_dir by sdf
	mulss xmm2, xmm0	
	mulss xmm3, xmm0

	movss xmm0, [ray_pos] ; mod ray_pos 0
	addss xmm0, xmm1
	movss xmm1, [space_wrap]
	call mod
	movss [ray_pos], xmm0

	movss xmm0, [ray_pos+4] ; mod ray_pos 4
	addss xmm0, xmm2
	movss xmm1, [space_wrap]
	call mod
	movss [ray_pos+4], xmm0

	movss xmm0, [ray_pos+8]
	addss xmm0, xmm3
	movss xmm1, [space_wrap]
	call mod
	movss [ray_pos+8], xmm0

	ret

get_sdf: ; returns sdf to xmm0
	
	movss xmm0, [ray_pos] ; load values for get_dist
	movss xmm1, [ray_pos+4]
	movss xmm2, [ray_pos+8]
	movss xmm3, [sp_pos]
	movss xmm4, [sp_pos+4]
	movss xmm5, [sp_pos+8]

	call get_dist

	movss xmm1, [sp_rad]
	subss xmm0, xmm1

	ret

get_dist: ; returns dist to xmm0 from xmm0-5

	subss xmm0, xmm3 ; get differences
	subss xmm1, xmm4
	subss xmm2, xmm5

	mulss xmm0, xmm0 ; square differences
	mulss xmm1, xmm1
	mulss xmm2, xmm2

	addss xmm0, xmm1 ; sum squares
	addss xmm0, xmm2

	sqrtss xmm0, xmm0 ; sqrt sum

	ret

mod: ; xmm0 mod xmm1

	sub rsp, 48
	movaps [rsp], xmm1
	movaps [rsp+16], xmm2
	movaps [rsp+32], xmm3
	
	movss xmm3, xmm0
	divss xmm0, xmm1
	roundss xmm2, xmm0, 1
	mulss xmm2, xmm1
	movss xmm0, xmm3
	subss xmm0, xmm2

	movaps xmm3, [rsp+32]
	movaps xmm2, [rsp+16]
	movaps xmm1, [rsp]
	add rsp, 48

	ret
