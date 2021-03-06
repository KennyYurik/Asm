extern _puts, _printf, _exit

section .data
	error_str db "error", 10, 0
	buffer1 times 32 db 0
	buffer2 times 51 db 0
	buffer3 times 51 db 0
	trailing db 0
	sign db 0
	length db 0
	flags db 0000b
	; XXYZb 
	; XX - sign of positive, 00 - nothing, 01 - ' ', 11 - '+'
	; Y - fill char, 0 - ' ', 1 - '0'
	; Z - align, 0 - right, 1 - left
	str_format db "%s", 0
	int_format db "%d ", 0
	char_format db "%c", 0
section .text
global _main

_print_err:
	push error_str
	call _puts
	add esp, 4
	push dword 1
	call _exit

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
	xor ah, 1
	or al, ah
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
	mul dx ; al * dx; res in dx:ax
	add eax, ecx
	cmp eax, 50
	ja _print_err ; too long
	mov ebx, eax
	inc esi
	jmp read_length
	
	
end_of_format_string:
	mov [length], bl
	
check_minus:
	mov al, [edi]
	cmp al, 0
	je _print_err
	cmp al, '-'
	jne check_correct
	mov al, [sign]
	xor al, 1
	mov [sign], al
	inc edi

check_correct:
	mov al, [edi]
	cmp al, 0
	je _print_err
	mov ecx, 0
	
loop1:
	cmp ecx, 33
	je _print_err
	xor eax, eax
	xor ebx, ebx
	mov al, [edi + ecx]
	cmp al, 0
	je end_loop1
	lea ebx, [eax - '0']
	cmp ebx, 9
	jbe this_is_digit
	lea ebx, [eax - 'A']
	cmp ebx, 5
	jbe this_is_letter
	jmp _print_err ; other char

this_is_digit:
	mov [edi + ecx], bl
	inc ecx
	jmp loop1
	
this_is_letter:
	add bl, 10
	mov [edi + ecx], bl
	inc ecx
	jmp loop1
	;-----------------------------------100% works
end_loop1: ; length in ecx
	cmp ecx, 32
	jne not_dopcode
	mov al, [edi]
	cmp al, 8
	jl not_dopcode
	; make normal form
	mov al, [sign]
	xor al, 1
	mov [sign], al
	mov ebx, 0
	
loop2: ; from dopcode
	mov al, [edi + ebx]
	xor al, 1111b
	mov [edi + ebx], al
	inc ebx
	cmp ebx, 32
	jne loop2

end_inverting: ; lets add 1 now
	mov ebx, 31
	
loop3:
	mov al, [edi + ebx]
	inc al
	mov [edi + ebx], al
	cmp al, 16
	jne not_dopcode
	xor al, al
	mov [edi + ebx], al
	dec ebx
	jmp loop3
	
not_dopcode: ; now decode from hex to dec. length = ecx
	dec ecx
	mov esi, edi
	add esi, ecx ; hex is [edi...esi]
	push edi
	xor ebx, ebx	
	
loop6:
	; al - ostatok
	xor ecx, ecx
	xor eax, eax 
	
	loop5: ; div 10 
		
		xor edx, edx
		shl eax, 4
		mov dl, [edi]		
		add al, dl
		mov dh, 10
		div dh ; ax / dh = al (ost ah)
		mov [edi], al
		mov al, ah
		mov ah, 0
		cmp edi, esi
		je end_loop5
		inc edi
		jmp loop5
		
	end_loop5:
		mov [buffer2 + ebx], al
		inc ebx
		cmp ebx, 50
		mov edi, [esp]
		jne loop6
	
	pop edi
	mov edi, buffer2	
	mov ecx, 49
	
end_of_decoding: ;deleting trailing zeros		
	mov al, [edi + ecx]
	cmp al, 0
	jne found_pos_not_zero
	cmp ecx, 0
	je found_pos_not_zero
	dec ecx
	jmp end_of_decoding
	
found_pos_not_zero:
	xor ebx, ebx
	push ecx
	
loop7:
	mov al, [edi + ecx]
	add al, '0'
	mov [buffer3 + ebx], al
	cmp ecx, 0
	je end_loop7
	dec ecx
	inc ebx
	jmp loop7
	
end_loop7: ; [esp] - length of converted string - 1
	pop ecx
	inc ecx
	; let's add sign
	xor eax, eax
	mov al, [sign]
	xor ebx, ebx
	mov bl, [flags]
	and bl, 1100b
	or al, bl
	jz positive_no_sign
	; set sign
	xor eax, eax
	mov al, [sign]
	cmp al, 0
	jne set_minus_sign
	; set plus sign
	xor eax, eax
	mov al, [flags]
	and al, 1000b
	cmp al, 0
	je set_space_plus_sign
	mov al, '+'
	mov [sign], al
	jmp check_align
	
set_space_plus_sign:
	mov al, '_'
	mov [sign], al
	jmp check_align
	
set_minus_sign:
	mov al, '-'
	mov [sign], al

check_align:	
	; check align
	xor eax, eax
	mov al, [flags]
	and al, 1
	cmp al, 1
	jne right_align_with_sign
	; left align
	xor eax, eax
	mov al, [sign]
	
	pusha
	push eax
	push char_format
	call _printf
	add esp, 8
	popa
	
	pusha
	push buffer3
	push str_format
	call _printf
	add esp, 8
	popa
	
	xor eax, eax
	mov al, [length]
	sub eax, ecx
	dec eax
	
	pusha
	push eax
	xor ebx, ebx
	mov bl, '_'
	push ebx
	call _printchars
	add esp, 8
	popa
	jmp main_end
	
right_align_with_sign:
	
	xor eax, eax ; compute length of trailing
	mov al, [length]
	sub eax, ecx
	dec eax	
	mov edi, eax
	
	
	xor eax, eax
	mov al, [flags]
	and al, 10b
	cmp al, 0	
	jne right_align_sign_zeros
	; spaces
	
	pusha
	push edi
	xor ebx, ebx
	mov bl, '_'
	push ebx
	call _printchars
	add esp, 8
	popa
	
	
	xor eax, eax
	mov al, [sign]
	pusha
	push eax
	push char_format
	call _printf
	add esp, 8
	popa
	
	pusha
	push buffer3
	push str_format
	call _printf
	add esp, 8
	popa
	jmp main_end
	
right_align_sign_zeros:
	
	xor eax, eax
	mov al, [sign]
	pusha
	push eax
	push char_format
	call _printf
	add esp, 8
	popa
	
	pusha
	push edi
	xor ebx, ebx
	mov bl, '0'
	push ebx
	call _printchars
	add esp, 8
	popa
	
	
	pusha
	push buffer3
	push str_format
	call _printf
	add esp, 8
	popa
	jmp main_end
	
	
	
	
positive_no_sign:
	
check_align_positive:	
	; check align
	xor eax, eax
	mov al, [flags]
	and al, 1
	cmp al, 1
	jne right_align_positive
	; left align
	pusha
	push buffer3
	push str_format
	call _printf
	add esp, 8
	popa
	
	xor eax, eax
	mov al, [length]
	sub eax, ecx
	
	pusha
	push eax
	xor ebx, ebx
	mov bl, '_'
	push ebx
	call _printchars
	add esp, 8
	popa
	jmp main_end
	
right_align_positive:
	
	xor eax, eax ; compute length of trailing
	mov al, [length]
	sub eax, ecx
	mov edi, eax
	
	xor eax, eax
	mov al, [flags]
	and al, 10b
	cmp al, 0	
	jne right_align_positive_zeros
	; spaces
	
	pusha
	push edi
	xor ebx, ebx
	mov bl, '_'
	push ebx
	call _printchars
	add esp, 8
	popa
	
	pusha
	push buffer3
	push str_format
	call _printf
	add esp, 8
	popa
	jmp main_end
	
right_align_positive_zeros:
	
	pusha
	push edi
	xor ebx, ebx
	mov bl, '0'
	push ebx
	call _printchars
	add esp, 8
	popa
	
	
	pusha
	push buffer3
	push str_format
	call _printf
	add esp, 8
	popa
	jmp main_end

main_end:
 	ret ; main ret
	
_printchars:
	mov eax, [esp + 4]
	mov ecx, [esp + 8]
	pusha
	
_loop_print:
	cmp ecx, 0
	jle end_loop_printchar
	pusha
	push eax
	push char_format
	call _printf
	add esp, 8
	popa
	dec ecx
	jmp _loop_print
	
end_loop_printchar:	
	popa	
	ret