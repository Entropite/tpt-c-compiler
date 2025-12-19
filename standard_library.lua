local Standard_Library = {}

Standard_Library.code = [[
__print_unsigned_int:
	test %1, %1
	jnz .__print_unsigned_int_not_zero
	mov %1, '0'
	st %1, term_print
	jmp .__print_unsigned_int_exit
.__print_unsigned_int_not_zero:
	mov %2, 4		; p = 4
.__print_unsigned_int_fixed_point:
	mulh %3, %1, 52429	; q = (n * 52429) >> 16
	shr %3, 3		; q >>= 3
	mul %4, %3, 10		; d*q
	sub %1, %4		; remainder = n - d*q
	st %1, %2, .__print_unsigned_int_buf		
	sub %2, 1		; p--;
	movf %1, %3		; n = q
	jnz .__print_unsigned_int_fixed_point

	add %2, 1
.__print_unsigned_int_print_int:
	ld %1, %2, .__print_unsigned_int_buf
	add %1, '0'
	st %1, term_print
	add %2, 1
	cmp %2, 5
	jne .__print_unsigned_int_print_int
	
.__print_unsigned_int_exit:
	ret
.__print_unsigned_int_buf:
	dw 0, 0, 0, 0, 0

__print_signed_int:
    cmp %1, 0
    jge .__print_signed_int_not_negative
    mov %2, '-'
    st %2, term_print
	xor %1, 65535
    add %1, 1
.__print_signed_int_not_negative:
    call __print_unsigned_int
    ret
    
__print_char_array:
    ld %2, %1
    test %2, %2
    jz __print_char_array_exit
    st %2, term_print
    add %1, 1
    jmp __print_char_array
__print_char_array_exit:
    ret

putchar:
    st %1, term_print
    ret

getchar:
    ld return_reg, term_input
    test return_reg, return_reg
    jz getchar
    ret

set_colour:
    st %1, term_colour
    ret

set_cursor:
    st %1, term_cursor
    ret

__scanf_unsigned_int:
    mov %2, 0
__scanf_unsigned_int_loop:
    call getchar
    sub return_reg, '0'
    cmp return_reg, 9
    jg __scanf_unsigned_int_not_digit 
    mull %2, 10
    add %2, return_reg
    jmp __scanf_unsigned_int_loop
__scanf_unsigned_int_not_digit:
    st %2, %1
    ret


]]

return Standard_Library