local Standard_Library = {}

Standard_Library.code = {}
Standard_Library.code["__print_unsigned_int"] =  [[
__tptcc_fn_print_unsigned_int:
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
	st %1, term_reg, term_base
	add %2, 1
	cmp %2, 5
	jne .__print_unsigned_int_print_int
	
.__print_unsigned_int_exit:
	ret
.__print_unsigned_int_buf:
	dw 0, 0, 0, 0, 0
]]

Standard_Library.code["__print_signed_int"] = [[
__tptcc_fn_print_signed_int:
    cmp %1, 0
    jge .__print_signed_int_not_negative
    mov %2, '-'
    st %2, term_reg, term_base
	xor %1, 65535
    add %1, 1
.__print_signed_int_not_negative:
    call __tptcc_fn_print_unsigned_int
    ret
]]

Standard_Library.code["__print_char_array"] = [[
__tptcc_fn_print_char_array:
    ld %2, %1
    test %2, %2
    jz .__print_char_array_exit
    st %2, term_reg, term_base
    add %1, 1
    jmp __tptcc_fn_print_char_array
.__print_char_array_exit:
    ret
]]

Standard_Library.code["putchar"] = [[
__tptcc_fn_putchar:
    st %1, term_reg, term_base
    ret
]]

Standard_Library.code["getchar"] = [[
__tptcc_fn_getchar:
    ld return_reg, term_input
    test return_reg, return_reg
    jz __tptcc_fn_getchar
    ret
]]

Standard_Library.code["getchar_nb"] = [[
__tptcc_fn_getchar_nb:
    ld return_reg, term_input
    ret
]]

Standard_Library.code["set_colour"] = [[
__tptcc_fn_set_colour:
    ; %1 = background, %2 = foreground
    shl %1, 4
    add %1, %2
    st %1, term_colour
    ret
]]

Standard_Library.code["set_text_colour"] = [[
__tptcc_fn_set_text_colour:
    st %1, term_colour
    ret
]]

Standard_Library.code["__send_raw"] = [[
__tptcc_fn_send_raw:
    st %1, %2
    ret
]]

Standard_Library.code["__set_zero_char"] = [[
__tptcc_fn_set_zero_char:
    exh %2, r0, %2
    mov %1, %2, %1
    st %1, term_print_e
    exh %4, r0, %4
    mov %3, %4, %3
    st %3, term_print_o
    ret
]]

Standard_Library.code["set_cursor"] = [[
__tptcc_fn_set_cursor:
    ; %1 = row, %2 = column
    shl %1, 5
    add %1, %2
    st %1, term_cursor
    ret
]]

Standard_Library.code["__scan_unsigned_int"] = [[
__tptcc_fn_scan_unsigned_int:
    mov %2, 0
__scan_unsigned_int_loop:
    call __tptcc_fn_getchar
    st return_reg, term_reg, term_base
    sub return_reg, '0'
    cmp return_reg, 9
    jg __scan_unsigned_int_not_digit
    cmp return_reg, 0
    jl __scan_unsigned_int_not_digit
    mull %2, 10
    add %2, return_reg
    jmp __scan_unsigned_int_loop
__scan_unsigned_int_not_digit:
    st %2, %1
    ret

]]
    
Standard_Library.code["vscroll"] = [[
__tptcc_fn_vscroll:
    mov %1, ' '
    st %1, term_raw
    ret
]]

Standard_Library.code["hscroll"] = [[
__tptcc_fn_hscroll:
    mov %1, ' '
    st %1, term_base
    ret
]]

Standard_Library.code["set_terminal_mode"] = [[
__tptcc_fn_set_terminal_mode:
    mov term_reg, %1
    ret
]]
    
Standard_Library.code["get_terminal_mode"] = [[
__tptcc_fn_get_terminal_mode:
    mov return_reg, term_reg
    ret
]]

Standard_Library.code["plot"] = [[
__tptcc_fn_plot:
    ; %1 = column/x, %2 = row/y, %3 = colour
    shl %2, 8
    add %2, %1
    st %2, %3, term_plot
    ret
]]

Standard_Library.code["set_hrange"] = [[
__tptcc_fn_set_hrange:
    ; %1 = start column, %2 = end column
    shl %2, 5
    add %2, %1
    st %2, term_hrange
    ret
]]

Standard_Library.code["set_vrange"] = [[
__tptcc_fn_set_vrange:
    ; %1 = start row, %2 = end row
    shl %2, 5
    add %2, %1
    st %2, term_vrange
    ret
]]

return Standard_Library