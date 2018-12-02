; Florian S.
; Solves Day 2 puzzle 1 in almost raw x64 assembly (except for memory allocation, because I cannot be bothered with that)

; Imports and Exports
global main
extern malloc
extern free

; File to read, because I was too lazy for argv
SECTION .data
input_file: db "box_ids.txt",0

; Reserve space for stat struct and one counter array
SECTION .bss
stat_data: resb 144
temp_count: resd 26

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
	call calc_checksum

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

calc_checksum:
	push rbp
	mov  rbp, rsp

	push rbx

	mov rbx, temp_count
	xor rdx, rdx; found two or three flag
	xor r8, r8 	; Two Counter
	xor r9,r9	; Three Counter
	xor r10,r10 ; file_ended
	xor rax, rax
	mov rsi, rdi


	; Go through each line
	line_loop:

	; Get character and perform checks
	mov al, [rsi]
	test al, al
	jnz continue_al_compare
	inc r10
	jmp calc_checksum_new_line

	continue_al_compare:
	cmp al, 10
	je calc_checksum_new_line

	; Increase the correct counter
	inc DWORD [rbx + 4*rax - 4*97]
	jmp continue_line_loop

	; Get entries for the line
	calc_checksum_new_line:
	xor rcx, rcx

	; Find duplicates
	duplicate_finder_loop:
	cmp rcx, 26
	jge duplicate_done

	; Check for 2
	mov eax, DWORD [rbx + 4*rcx]
	cmp eax, 2
	je duplicate_increase_two

	; Check for 3
	cmp eax, 3
	jne continue_duplicate

	; Did we already count a 3?
	test rdx, 2
	jnz continue_duplicate
	inc r9
	or 	rdx , 2
	jmp	continue_duplicate

	; Did we already count a 2?
	duplicate_increase_two:
	test rdx, 1
	jnz	continue_duplicate
	inc r8
	or rdx , 1

	; Reset the array and continue to the next entry
	continue_duplicate:
	mov DWORD [rbx + 4*rcx], 0
	inc rcx
	jmp duplicate_finder_loop

	; Reset various variables
	duplicate_done:
	xor rdx, rdx
	xor rax, rax
	test r10, r10	; File done check
	jnz calc_checksum_file_done

	continue_line_loop:
	inc rsi
	jmp line_loop

	calc_checksum_file_done:
	xor rax, rax
	imul r8, r9
	mov rax, r8

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
