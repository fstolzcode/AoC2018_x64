; Florian S.
; Solves Day 1 Puzzle 2 in almost raw x64 assembly (except for memory allocation, because I cannot be bothered with that)

; Imports and Exports
global main
extern malloc
extern free

extern init_dynarr
extern free_dynarr
extern dynarr_push_back

struc dynarr 
	.ptr:	resq     1 
	.size:	resd	 1
	.max:	resd 	 1
endstruc

; File to read, because I was too lazy for argv
SECTION .data
input_file: db "input.txt",0

; Reserve space for stat struct
SECTION .bss
stat_data: resb 144

; The actual code
SECTION .text
main:
	push rbp
	mov  rbp, rsp

	push rbx

	; Get file_size
	call get_file_size
	cmp rax, -1
	je error_case

	; Get file content
	mov rdi, rax
	call read_file
	cmp rax, -1
	je error_case

	; Compute frequency
	mov rbx, rax
	mov rdi, rax
	call calc_frequency

	; Result is in RAX, afterwards in RBX, no printing
	; Free buffer
	xchg rbx, rax
	mov rdi, rax
	call free

	; Get result in RAX
	mov rax, rbx
	pop rbx
	jmp epilog

	; Error
	error_case:
	mov rax, -1

	epilog:
	mov rsp, rbp
	pop rbp

	ret

; Adjusted for Problem 2
calc_frequency:
	push rbp
	mov  rbp, rsp

	; Lots of saving required
	push rbx
	push r12
	push r13
	push r14
	push r15

	xor r14, r14	; dynamic array
	mov r12, rdi 	; Saved start of buffer
	
	; Create dynamic array and init with 0
	call init_dynarr
	mov r14, rax
	mov rdi, rax
	xor rsi, rsi
	call dynarr_push_back

	xor rbx, rbx

	restart_buffer:
	mov rsi, r12
	; Go through each character, if NULLBYTE stop
	frequency_loop:
	mov al, [rsi]
	test al,al
	jz restart_buffer ; End of file, "seek back to the start"

	; Check whether to increase or decrease or ingore
	cmp al, '+'
	je 	increase_frequency
	cmp al, '-'
	je 	decrease_frequency
	jmp continue_frequency

	; Parse number and then add
	increase_frequency:
	inc rsi
	mov rdi, rsi
	call parse_decimal
	add rbx, rax
	jmp start_compare

	; Parse number and then subtract
	decrease_frequency:
	inc rsi
	mov rdi, rsi
	call parse_decimal
	sub rbx, rax

	; Look into the dynamic array and look for the element (with horrible O(n))
	start_compare:
	mov r13, [r14]
	xor ecx, ecx

	compare_loop:
	cmp ecx, DWORD [r14 + dynarr.size]
	jge stop_compare
	xor rdx, rdx
	mov edx, DWORD [r13 + 4*rcx]
	cmp rbx, rdx
	je calc_frequency_epilog
	inc ecx
	jmp compare_loop

	; We did not find it and we add the element to the array
	stop_compare:
	mov rdi, r14
	mov r15, rsi
	mov rsi, rbx 	; save
	call dynarr_push_back
	mov rsi, r15

	; Increase string pointer
	continue_frequency:
	inc rsi
	jmp frequency_loop

	; Epilog
	calc_frequency_epilog:
	mov rdi, r14
	call free_dynarr
	mov rax, rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

	mov rsp, rbp
	pop rbp
	ret

read_file:
	push rbp
	mov rbp, rsp

	; Save size
	mov r8, rdi

	; Call malloc with size
	call malloc
	test rax, rax
	jle read_file_error
	mov r9, rax

	; Get file descripter
	mov rax, 2
	mov rdi, input_file
	xor rsi, rsi
	xor rdx, rdx

	syscall
	test rax, rax
	jle read_file_error
	mov r10, rax

	; Read complete file
	xor rax, rax
	mov rdi, r10
	mov rsi, r9
	mov rdx, r8

	syscall
	test rax, rax
	jle read_file_error

	; Close the file
	mov rax, 3
	mov rdi, r10

	syscall

	; Return the buffer
	mov rax, r9
	jmp read_file_epilog

	read_file_error:
	mov rax, -1

	read_file_epilog:
	mov rsp, rbp
	pop rbp
	ret


get_file_size:
	push rbp
	mov rbp, rsp

	; Call sys_stat
	mov rax, 4
	mov rdi, input_file
	mov rsi, stat_data

	syscall

	test rax, rax
	jz no_stat_error
	mov rax, -1
	jmp get_file_size_epilog

	; Get the size field
	no_stat_error:
	xor rax, rax
	mov eax, [stat_data + 0x30]

	get_file_size_epilog:
	mov rsp, rbp
	pop rbp
	ret

parse_decimal:
	push rbp
	mov rbp, rsp

	xor rax, rax
	xor rcx, rcx
	xor rdx, rdx

	mov rsi, rdi

	; Read at most 18 digits (almost 64 bit value)
	parse_decimal_loop:
	cmp rcx, 18
	jge parse_decimal_done

	; Read one char
	mov dl, [rsi + rcx]

	; Test for number
	test dl,dl
	jz parse_decimal_done
	cmp dl, 48
	jl parse_decimal_done
	cmp dl, 57
	jg parse_decimal_done

	; Get actual decimal value instead of ASCII
	; Add it to rax
	sub dl, 48
	imul rax, 10
	add rax, rdx

	; Next char
	inc rcx
	jmp parse_decimal_loop

	parse_decimal_done:
	mov rsp, rbp
	pop rbp

	ret
