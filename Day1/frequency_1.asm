; Florian S.
; Solves Day 1 puzzle one in almost raw x64 assembly (except for memory allocation, because I cannot be bothered with that)

; Imports and Exports
global main
extern malloc
extern free

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

calc_frequency:
	push rbp
	mov  rbp, rsp

	push rbx

	xor rbx, rbx
	mov rsi, rdi
	xor rcx, rcx

	; Go through each character, if NULLBYTE stop
	frequency_loop:
	mov al, [rsi]
	test al,al
	jz calc_frequency_epilog

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
	jmp continue_frequency

	; Parse number and then subtract
	decrease_frequency:
	inc rsi
	mov rdi, rsi
	call parse_decimal
	sub rbx, rax

	; Increase string pointer
	continue_frequency:
	inc rsi
	jmp frequency_loop

	; Epilog
	calc_frequency_epilog:
	mov rax, rbx
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
