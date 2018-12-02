; Florian S.
; Implements dynamic (u)int_32 arrays in x64

; Export
global init_dynarr
global free_dynarr
global dynarr_push_back

; Import
extern malloc
extern free
extern realloc

; Struct for dynamic array
struc dynarr 
	.ptr:	resq     1 
	.size:	resd	 1
	.max:	resd 	 1
endstruc


;Create a dynamic array
init_dynarr:
	push rbp
	mov  rbp, rsp

	push rbx

	; Allocate enough memory to fit the struct
	mov rdi, dynarr_size
	call malloc
	test rax, rax
	jle init_dynarr_error

	; Init the struct with size = 0 and a max size of 32
	mov rbx, rax

	mov [rbx + dynarr.size], DWORD 0
	mov [rbx + dynarr.max], DWORD 32

	; Allocate inner pointer
	mov rdi, 32*4
	call malloc
	test rax, rax
	jle init_dynarr_error

	mov [rbx + dynarr.ptr], rax

	mov rax, rbx

	jmp init_dynarr_epilog

	init_dynarr_error:
	mov rax, -1

	init_dynarr_epilog:
	pop rbx
	mov rsp, rbp
	pop rbp

	ret

; Push a new element to the dynamic array
dynarr_push_back:
	push rbp
	mov  rbp, rsp

	push rbx
	push r12

	; Save the parameters
	mov rbx, rdi
	mov r12, rsi

	; Get important parameters
	mov eax, DWORD [rbx + dynarr.size]
	mov edx, DWORD [rbx + dynarr.max]

	; Did we reach the limit?
	cmp eax, edx
	jl dynarr_resize_skip

	; If yes, then increase the size of the array by 32
	add edx, 32
	mov DWORD [rbx + dynarr.max], edx
	mov rdi, [rbx]
	mov esi, edx
	imul esi, 4
	call realloc
	test rax, rax
	jle dynarr_push_back_error
	mov [rbx], rax

	; Add the element to the array and increase the size
	dynarr_resize_skip:
	xor rax, rax
	mov rdi, [rbx]
	mov eax, [rbx + dynarr.size]
	mov DWORD [rdi + 4*rax], r12d
	inc DWORD [rbx + dynarr.size]

	jmp dynarr_push_back_epilog

	dynarr_push_back_error:
	mov rax, -1

	dynarr_push_back_epilog:
	pop r12
	pop rbx

	mov rsp, rbp
	pop rbp

	ret

; Free the array
free_dynarr:
	push rbp
	mov  rbp, rsp

	push rbx
	mov rbx, rdi

	; First free the inner pointer
	mov rdi, [rbx]
	call free

	; Then free the struct pointer
	mov rdi,rbx
	call free

	pop rbx

	mov rsp, rbp
	pop rbp

	ret