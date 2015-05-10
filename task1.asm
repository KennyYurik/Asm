extern _puts, _printf

section .data
	error_str db "error", 10, 0
	output_str db 1,2,3
	length db 0
	flags db 0000b
	; XXYZb 
	; XX - sign of positive, 00 - nothing, 01 - ' ', 11 - '+'
	; Y - fill char, 0 - ' ', 1 - '0'
	; Z - align, 0 - right, 1 - left
	int_format db "%d %x", 0
	
section .text
global _main

_print_err:
	push error_str
	call _puts
	add esp, 4
	ret

_main:
	mov edx, [esp + 4] ; argc
	cmp edx, 3
	jne _print_err ; bad arguments
	
	mov ebx, [esp + 8] ; argV
	mov esi, [ebx + 4] ; argv[1]
	mov edi, [ebx + 8] ; argv[2]
	
read_flags:
	xor eax, eax
	xor ebx, ebx
	mov al, [esi]
	cmp al, 0 ; end of flags
	je read_length
	lea ecx, [eax - '1']
	cmp ecx, 9 ; digit
	jb read_length
	cmp al, ' '
	je set_space_flag
	cmp al, '-'
	je set_minus_flag
	cmp al, '+'
	je set_plus_flag
	cmp al, '0'
	je set_zero_flag
	jmp _print_err ; other shit
	
end_read_flags:
	inc esi 
	jmp read_flags ; go next char
	
set_space_flag:
	mov al, [flags]
	or al, 0100b
	mov [flags], al
	jmp end_read_flags
	
set_plus_flag:
	mov al, [flags]
	or al, 1100b
	mov [flags], al
	jmp end_read_flags
	
set_minus_flag:
	mov al, [flags]
	mov ah, al
	and ah, 10b
	shr ah, 1
	xor al, ah
	mov [flags], al
	jmp end_read_flags
	
set_zero_flag:
	mov al, [flags]
	or al, 0010b
	and al, 11111110b
	mov [flags], al
	jmp end_read_flags
	
read_length:
	xor eax, eax
	mov al, [esi]
	cmp al, 0
	je end_of_format_string
	lea ecx, [eax - '0']
	cmp ecx, 9 ; not digit
	ja _print_err
	mov ax, bx
	mov dx, 10
	mul dx ; al * dx; res in eax
	add eax, ecx
	cmp eax, 50
	ja _print_err ; too long
	mov ebx, eax
	inc esi
	jmp read_length
	
	
end_of_format_string:
	mov [length], bl
	xor eax, eax
	mov al, [flags]
	push eax
	push ebx
	push int_format
	call _printf
	add esp, 12
	
	
	ret ; main ret