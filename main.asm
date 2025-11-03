%include "common"

%define return_reg r31
%define stack_pointer r30
%define base_pointer r29
%define term_reg r28
%define return_addr_reg r27


%macro push thing
    subs stack_pointer, 1
    st thing, stack_pointer
%endmacro

%macro pop thing
    ld thing, stack_pointer
    adds stack_pointer, 1
%endmacro

%macro call thing
    push return_addr_reg
    jmp return_addr_reg, thing
%endmacro

%macro ret
    mov r2, return_addr_reg
    pop return_addr_reg
    jmp r2
%endmacro

%macro mull x, y
    mul x, x, y
%endmacro

    mov term_reg, 0x9F80
                              
    ld r0, term_reg                
    mov r1, { 11 5 << }
    st r1, term_reg, 0x42
    mov r1, { 7 5 << }
    st r1, term_reg, 0x43
    mov r17, 0x1000
    st r17, term_reg, 0x44
    mov r17, 0xF
    st r17, term_reg, 0x46
    mov r17, 1
    st r17, term_reg, 0x45

start:
    mov stack_pointer,2047
	mov r5, 8
	st r5, 2047
	jmp main
fib:
	sub stack_pointer, 0
	push base_pointer
	mov base_pointer, stack_pointer
	ld r1, base_pointer, 2
	call print_num
	ld r8, base_pointer, 2
	ld r9, base_pointer, 3
	add r8, r9
	push r8
	ld r10, base_pointer, 3
	push r10
	call fib
	add stack_pointer, 2
.exit_fib:
	pop base_pointer
	add stack_pointer, 0
	ret
main:
	sub stack_pointer, 0
	push base_pointer
	mov base_pointer, stack_pointer
	mov r6, 1
	push r6
	mov r7, 0
	push r7
	call fib
	add stack_pointer, 2
.exit_main:
	pop base_pointer
	add stack_pointer, 0
	hlt
print_num:
	test r1, r1
	jnz .not_zero
	mov r1, '0'
	st r1, term_reg, 0x25
	jmp .exit
.not_zero:
	mov r2, 4		; p = 4
.fixed_point:
	mulh r3, r1, 52429	; q = (n * 52429) >> 16
	shr r3, 3		; q >>= 3
	mul r4, r3, 10		; d*q
	sub r1, r4		; remainder = n - d*q
	st r1, r2, .buf		
	sub r2, 1		; p--;
	movf r1, r3		; n = q
	jnz .fixed_point

	add r2, 1
.print_int:
	ld r1, r2, .buf
	add r1, '0'
	st r1, term_reg, 0x25
	add r2, 1
	cmp r2, 5
	jne .print_int
	
.exit:
	ret
.buf:
	dw 0, 0, 0, 0, 0