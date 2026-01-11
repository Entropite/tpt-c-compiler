%include "common"

%define return_reg r31
%define stack_pointer r30
%define base_pointer r29
%define term_reg r28
%define return_addr_reg r27

; Initialization and defining basic macros
%define term_base 0x9F80

%eval term_input  term_base 0x00 +
%eval term_raw    term_base 0x04 +
%eval term_single term_base 0x05 +
%eval term_print  term_base 0x25 +
%eval term_term   term_base 0x26 +
%eval term_hrange term_base 0x42 +
%eval term_vrange term_base 0x43 +
%eval term_cursor term_base 0x44 +
%eval term_nlchar term_base 0x45 +
%eval term_colour term_base 0x46 +
%eval term_print_e term_base 0x40 +
%eval term_print_o term_base 0x41 +


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
    mov r26, return_addr_reg
    pop return_addr_reg
    jmp r26
%endmacro

%macro mull x, y
    mul x, x, y
%endmacro

jmp init
global_data_section:
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 119, 121, 114, 124, 113, 116, 118, 117, 120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 75, 97, 98, 111, 111, 109, 33, 32, 89, 111, 117, 32, 108, 111, 115, 101, 33, 0, 35, 32, 111, 102, 32, 109, 105, 110, 101, 115, 10, 40, 54, 45, 49, 50, 41, 58, 32, 0, 10, 69, 110, 116, 101, 114, 32, 97, 10, 110, 117, 109, 98, 101, 114, 32, 116, 111, 10, 104, 101, 108, 112, 10, 114, 97, 110, 100, 111, 109, 105, 122, 101, 10, 40, 49, 45, 49, 48, 48, 41, 58, 32, 0, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 0, 89, 111, 117, 32, 119, 105, 110, 33, 0
init:
    mov term_reg, 0x9F80
                              
    ld r0, term_reg                
    mov r1, { 11 5 << }
    st r1, term_hrange
    mov r1, { 7 5 << }
    st r1, term_vrange
    mov r1, 0x1000
    st r1, term_cursor
    mov r1, 0xF
    st r1, term_colour
    mov r1, 10
    st r1,  term_nlchar

start:
    mov stack_pointer,4095
	jmp main
__scan_signed_int:
	push base_pointer
	mov base_pointer, stack_pointer
	push r1
	push r2
	push r3
	push r4
	push r5
	mov r2, 0
	mov r3, 1
	call getchar
	mov r3, return_reg
	mov r1, r3
	cmp r3, '-'
	je .label_1
	jmp .label_0
	.label_1:
	mov r3, 65535
	jmp .label_2
	.label_0:
	mov r3, 1
	mov r2, r1
	sub r2, '0'
	.label_2:
	mov r22, r1
	call putchar
	.label_3:
	call getchar
	mov r4, return_reg
	mov r1, r4
	cmp r4, '0'
	jge .label_6
	jmp .label_4
	.label_6:
	mov r4, r1
	cmp r4, '9'
	jle .label_5
	jmp .label_4
	.label_5:
	mov r22, r1
	call putchar
	mull r2, 10
	sub r1, '0'
	add r2, r1
	jmp .label_3
	.label_4:
	cmp r3, 65535
	je .label_8
	jmp .label_7
	.label_8:
	xor r2, 65535
	add r2, 1
	jmp .label_9
	.label_7:
	.label_9:
	ld r3, base_pointer, 2
	st r2, r3
	mov return_reg, r1
	jmp .exit___scan_signed_int
.exit___scan_signed_int:
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop base_pointer
	ret
show_bombs:
	push base_pointer
	mov base_pointer, stack_pointer
	push r1
	push r2
	push r3
	push r4
	mov r2, 0
	.label_10:
	mov r1, r2
	cmp r1, 8
	jl .label_13
	jmp .label_12
	.label_13:
	mov r3, 0
	.label_14:
	mov r1, r3
	cmp r1, 12
	jl .label_17
	jmp .label_16
	.label_17:
	mov r1, 97
	mov r4, r2
	mull r4, 12
	add r1, r4
	ld r1, r1, r3
	cmp r1, 9
	jge .label_19
	jmp .label_18
	.label_19:
	mov r1, r2
	shl r1, 5
	add r1, r3
	mov r22, r1
	call set_cursor
	mov r22, 79
	call set_colour
	mov r25, 39294
	mov r24, 32511
	mov r23, 53118
	mov r22, 20121
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_20
	.label_18:
	.label_20:
	.label_15:
	mov r1, r3
	add r3, 1
	jmp .label_14
	.label_16:
	.label_11:
	mov r1, r2
	add r2, 1
	jmp .label_10
	.label_12:
.exit_show_bombs:
	pop r4
	pop r3
	pop r2
	pop r1
	pop base_pointer
	ret
sweep_cell:
	sub stack_pointer, 192
	push base_pointer
	mov base_pointer, stack_pointer
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	ld r1, base_pointer, 194
	ld r2, base_pointer, 195
	mov r3, 97
	mov r4, r1
	mull r4, 12
	add r3, r4
	ld r3, r3, r2
	cmp r3, 9
	jge .label_22
	jmp .label_21
	.label_22:
	call show_bombs
	mov r22, 0
	call set_cursor
	mov r22, 4
	call set_colour
	mov r3, 395
	mov r22, r3
	call __print_char_array
	mov r22, 9
	call set_colour
	mov r3, r1
	shl r3, 5
	add r3, r2
	mov r22, r3
	call set_cursor
	mov r22, 0
	call putchar
	.label_24:
	mov r3, 1
	cmp r3, 0
	je .label_25
	.label_26:
	jmp .label_24
	.label_25:
	jmp .label_23
	.label_21:
	.label_23:
	add r3, base_pointer, 1
	mov r4, 0
	add r5, r3, 0
	st r1, r5
	add r1, r3, 1
	st r2, r1
	mov r1, 2
	add r3, r1
	.label_27:
	mov r1, r3
	add r2, base_pointer, 1
	cmp r1, r2
	jg .label_29
	jmp .label_28
	.label_29:
	ld r1, r3, 65534
	ld r2, r3, 65535
	mov r5, 2
	sub r3, r5
	mov r5, 97
	mov r6, r1
	mull r6, 12
	add r5, r6
	ld r5, r5, r2
	mov r6, r5
	add r6, '0'
	mov r7, 1
	mov r8, r1
	mull r8, 12
	add r7, r8
	add r7, r2
	st r6, r7
	mov r7, r1
	shl r7, 5
	add r7, r2
	mov r22, r7
	call set_cursor
	mov r7, 289
	add r7, r5
	ld r22, r7
	call set_colour
	mov r22, r6
	call putchar
	mov r6, r4
	add r4, 1
	cmp r5, 0
	je .label_31
	jmp .label_30
	.label_31:
	mov r5, r1
	sub r5, 1
	mov r6, r2
	sub r6, 1
	mov r7, r1
	add r7, 1
	mov r8, r2
	add r8, 1
	mov r9, 193
	mov r10, r1
	mull r10, 12
	add r9, r10
	ld r9, r9, r2
	cmp r9, 0
	je .label_33
	.label_34:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 0
	je .label_37
	.label_39:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 'F'
	je .label_37
	jmp .label_36
	.label_37:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	add r9, r6
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r5, r9
	add r9, r3, 1
	st r6, r9
	mov r9, 2
	add r3, r9
	jmp .label_38
	.label_36:
	.label_38:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, 0
	je .label_41
	.label_43:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, 'F'
	je .label_41
	jmp .label_40
	.label_41:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	add r9, r8
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r5, r9
	add r9, r3, 1
	st r8, r9
	mov r9, 2
	add r3, r9
	jmp .label_42
	.label_40:
	.label_42:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 0
	je .label_45
	.label_47:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 'F'
	je .label_45
	jmp .label_44
	.label_45:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	add r9, r6
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r7, r9
	add r9, r3, 1
	st r6, r9
	mov r9, 2
	add r3, r9
	jmp .label_46
	.label_44:
	.label_46:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, 0
	je .label_49
	.label_51:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, 'F'
	je .label_49
	jmp .label_48
	.label_49:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	add r9, r8
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r7, r9
	add r9, r3, 1
	st r8, r9
	mov r9, 2
	add r3, r9
	jmp .label_50
	.label_48:
	.label_50:
	mov r9, 1
	mov r10, r1
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 0
	je .label_53
	.label_55:
	mov r9, 1
	mov r10, r1
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 'F'
	je .label_53
	jmp .label_52
	.label_53:
	mov r9, 1
	mov r10, r1
	mull r10, 12
	add r9, r10
	add r9, r6
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r1, r9
	add r9, r3, 1
	st r6, r9
	mov r6, 2
	add r3, r6
	jmp .label_54
	.label_52:
	.label_54:
	mov r6, 1
	mov r9, r1
	mull r9, 12
	add r6, r9
	ld r6, r6, r8
	cmp r6, 0
	je .label_57
	.label_59:
	mov r6, 1
	mov r9, r1
	mull r9, 12
	add r6, r9
	ld r6, r6, r8
	cmp r6, 'F'
	je .label_57
	jmp .label_56
	.label_57:
	mov r6, 1
	mov r9, r1
	mull r9, 12
	add r6, r9
	add r6, r8
	mov r9, 16
	st r9, r6
	add r6, r3, 0
	st r1, r6
	add r1, r3, 1
	st r8, r1
	mov r1, 2
	add r3, r1
	jmp .label_58
	.label_56:
	.label_58:
	mov r1, 1
	mov r6, r7
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	cmp r1, 0
	je .label_61
	.label_63:
	mov r1, 1
	mov r6, r7
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	cmp r1, 'F'
	je .label_61
	jmp .label_60
	.label_61:
	mov r1, 1
	mov r6, r7
	mull r6, 12
	add r1, r6
	add r1, r2
	mov r6, 16
	st r6, r1
	add r1, r3, 0
	st r7, r1
	add r1, r3, 1
	st r2, r1
	mov r1, 2
	add r3, r1
	jmp .label_62
	.label_60:
	.label_62:
	mov r1, 1
	mov r6, r5
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	cmp r1, 0
	je .label_65
	.label_67:
	mov r1, 1
	mov r6, r5
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	cmp r1, 'F'
	je .label_65
	jmp .label_64
	.label_65:
	mov r1, 1
	mov r6, r5
	mull r6, 12
	add r1, r6
	add r1, r2
	mov r6, 16
	st r6, r1
	add r1, r3, 0
	st r5, r1
	add r1, r3, 1
	st r2, r1
	mov r1, 2
	add r3, r1
	jmp .label_66
	.label_64:
	.label_66:
	jmp .label_35
	.label_33:
	mov r9, r1
	cmp r9, 0
	jg .label_69
	jmp .label_68
	.label_69:
	mov r9, r2
	cmp r9, 0
	jg .label_74
	jmp .label_71
	.label_74:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 0
	je .label_76
	.label_78:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, 'F'
	je .label_76
	jmp .label_75
	.label_76:
	mov r9, 1
	jmp .label_77
	.label_75:
	mov r9, 0
	.label_77:
	cmp r9, 0
	je .label_71
	.label_72:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	add r9, r6
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r5, r9
	add r9, r3, 1
	st r6, r9
	mov r9, 2
	add r3, r9
	jmp .label_73
	.label_71:
	.label_73:
	mov r9, r2
	cmp r9, 11
	jl .label_82
	jmp .label_79
	.label_82:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, 0
	je .label_84
	.label_86:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, 'F'
	je .label_84
	jmp .label_83
	.label_84:
	mov r9, 1
	jmp .label_85
	.label_83:
	mov r9, 0
	.label_85:
	cmp r9, 0
	je .label_79
	.label_80:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	add r9, r8
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r5, r9
	add r9, r3, 1
	st r8, r9
	mov r9, 2
	add r3, r9
	jmp .label_81
	.label_79:
	.label_81:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r2
	cmp r9, 0
	je .label_88
	.label_90:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r2
	cmp r9, 'F'
	je .label_88
	jmp .label_87
	.label_88:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	add r9, r2
	mov r10, 16
	st r10, r9
	add r9, r3, 0
	st r5, r9
	add r5, r3, 1
	st r2, r5
	mov r5, 2
	add r3, r5
	jmp .label_89
	.label_87:
	.label_89:
	jmp .label_70
	.label_68:
	.label_70:
	mov r5, r1
	cmp r5, 7
	jl .label_92
	jmp .label_91
	.label_92:
	mov r5, r2
	cmp r5, 0
	jg .label_97
	jmp .label_94
	.label_97:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r6
	cmp r5, 0
	je .label_99
	.label_101:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r6
	cmp r5, 'F'
	je .label_99
	jmp .label_98
	.label_99:
	mov r5, 1
	jmp .label_100
	.label_98:
	mov r5, 0
	.label_100:
	cmp r5, 0
	je .label_94
	.label_95:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	add r5, r6
	mov r9, 16
	st r9, r5
	add r5, r3, 0
	st r7, r5
	add r5, r3, 1
	st r6, r5
	mov r5, 2
	add r3, r5
	jmp .label_96
	.label_94:
	.label_96:
	mov r5, r2
	cmp r5, 11
	jl .label_105
	jmp .label_102
	.label_105:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r8
	cmp r5, 0
	je .label_107
	.label_109:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r8
	cmp r5, 'F'
	je .label_107
	jmp .label_106
	.label_107:
	mov r5, 1
	jmp .label_108
	.label_106:
	mov r5, 0
	.label_108:
	cmp r5, 0
	je .label_102
	.label_103:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	add r5, r8
	mov r9, 16
	st r9, r5
	add r5, r3, 0
	st r7, r5
	add r5, r3, 1
	st r8, r5
	mov r5, 2
	add r3, r5
	jmp .label_104
	.label_102:
	.label_104:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r2
	cmp r5, 0
	je .label_111
	.label_113:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r2
	cmp r5, 'F'
	je .label_111
	jmp .label_110
	.label_111:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	add r5, r2
	mov r9, 16
	st r9, r5
	add r5, r3, 0
	st r7, r5
	add r5, r3, 1
	st r2, r5
	mov r5, 2
	add r3, r5
	jmp .label_112
	.label_110:
	.label_112:
	jmp .label_93
	.label_91:
	.label_93:
	mov r5, r2
	cmp r5, 0
	jg .label_117
	jmp .label_114
	.label_117:
	mov r5, 1
	mov r7, r1
	mull r7, 12
	add r5, r7
	ld r5, r5, r6
	cmp r5, 0
	je .label_119
	.label_121:
	mov r5, 1
	mov r7, r1
	mull r7, 12
	add r5, r7
	ld r5, r5, r6
	cmp r5, 'F'
	je .label_119
	jmp .label_118
	.label_119:
	mov r5, 1
	jmp .label_120
	.label_118:
	mov r5, 0
	.label_120:
	cmp r5, 0
	je .label_114
	.label_115:
	mov r5, 1
	mov r7, r1
	mull r7, 12
	add r5, r7
	add r5, r6
	mov r7, 16
	st r7, r5
	add r5, r3, 0
	st r1, r5
	add r5, r3, 1
	st r6, r5
	mov r5, 2
	add r3, r5
	jmp .label_116
	.label_114:
	.label_116:
	cmp r2, 11
	jl .label_125
	jmp .label_122
	.label_125:
	mov r2, 1
	mov r5, r1
	mull r5, 12
	add r2, r5
	ld r2, r2, r8
	cmp r2, 0
	je .label_127
	.label_129:
	mov r2, 1
	mov r5, r1
	mull r5, 12
	add r2, r5
	ld r2, r2, r8
	cmp r2, 'F'
	je .label_127
	jmp .label_126
	.label_127:
	mov r2, 1
	jmp .label_128
	.label_126:
	mov r2, 0
	.label_128:
	cmp r2, 0
	je .label_122
	.label_123:
	mov r2, 1
	mov r5, r1
	mull r5, 12
	add r2, r5
	add r2, r8
	mov r5, 16
	st r5, r2
	add r2, r3, 0
	st r1, r2
	add r1, r3, 1
	st r8, r1
	mov r1, 2
	add r3, r1
	jmp .label_124
	.label_122:
	.label_124:
	.label_35:
	jmp .label_32
	.label_30:
	.label_32:
	jmp .label_27
	.label_28:
	ld r1, 298
	add r1, r4
	st r1, 298
.exit_sweep_cell:
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop base_pointer
	add stack_pointer, 192
	ret
add_to_surrounding_cells:
	push base_pointer
	mov base_pointer, stack_pointer
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	ld r4, base_pointer, 2
	ld r5, base_pointer, 3
	mov r1, r4
	sub r1, 1
	mov r3, r1
	mov r1, r5
	sub r1, 1
	mov r6, r1
	mov r1, r4
	add r1, 1
	mov r7, r1
	mov r1, r5
	add r1, 1
	mov r8, r1
	mov r1, r4
	cmp r1, 0
	jg .label_131
	jmp .label_130
	.label_131:
	mov r1, r5
	cmp r1, 0
	jg .label_134
	jmp .label_133
	.label_134:
	mov r1, 97
	mov r2, r3
	mull r2, 12
	add r1, r2
	add r1, r6
	ld r2, r1
	ld r9, base_pointer, 4
	add r2, r9
	st r2, r1
	jmp .label_135
	.label_133:
	.label_135:
	mov r1, 97
	mov r2, r3
	mull r2, 12
	add r1, r2
	mov r2, r1
	add r2, r5
	ld r9, r2
	ld r1, base_pointer, 4
	add r9, r1
	st r9, r2
	mov r1, r5
	cmp r1, 11
	jl .label_137
	jmp .label_136
	.label_137:
	mov r1, 97
	mov r2, r3
	mull r2, 12
	add r1, r2
	add r1, r8
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_138
	.label_136:
	.label_138:
	jmp .label_132
	.label_130:
	.label_132:
	mov r1, r5
	cmp r1, 0
	jg .label_140
	jmp .label_139
	.label_140:
	mov r1, 97
	mov r2, r4
	mull r2, 12
	add r1, r2
	add r1, r6
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_141
	.label_139:
	.label_141:
	mov r1, r5
	cmp r1, 11
	jl .label_143
	jmp .label_142
	.label_143:
	mov r1, 97
	mov r2, r4
	mull r2, 12
	add r1, r2
	add r1, r8
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_144
	.label_142:
	.label_144:
	mov r1, r4
	cmp r1, 7
	jl .label_146
	jmp .label_145
	.label_146:
	mov r1, r5
	cmp r1, 0
	jg .label_149
	jmp .label_148
	.label_149:
	mov r1, 97
	mov r2, r7
	mull r2, 12
	add r1, r2
	add r1, r6
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_150
	.label_148:
	.label_150:
	mov r1, 97
	mov r2, r7
	mull r2, 12
	add r1, r2
	add r1, r5
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	mov r1, r5
	cmp r1, 11
	jl .label_152
	jmp .label_151
	.label_152:
	mov r1, 97
	mov r2, r7
	mull r2, 12
	add r1, r2
	add r1, r8
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_153
	.label_151:
	.label_153:
	jmp .label_147
	.label_145:
	.label_147:
.exit_add_to_surrounding_cells:
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop base_pointer
	ret
main:
	sub stack_pointer, 2
	push base_pointer
	mov base_pointer, stack_pointer
	push r1
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	mov r1, 97
	mov r2, 9
	st r2, r1
	mov r1, 97
	mov r2, 413
	mov r22, r2
	call __print_char_array
	add r2, base_pointer, 1
	push r2
	call __scan_signed_int
	add stack_pointer, 1
	mov r2, return_reg
	ld r2, base_pointer, 1
	mov r3, 96
	sub r3, r2
	mov r4, r3
	mov r22, 14
	call set_colour
	mov r3, 433
	mov r22, r3
	call __print_char_array
	add r3, base_pointer, 2
	push r3
	call __scan_signed_int
	add stack_pointer, 1
	mov r3, return_reg
	ld r3, base_pointer, 2
	xor r3, 65535
	add r3, 1
	mov r22, 10
	call putchar
	mov r22, 136
	call set_colour
	mov r22, 224
	call set_cursor
	mov r5, 477
	mov r22, r5
	call __print_char_array
	mov r22, 224
	call set_cursor
	mov r22, 34
	call set_colour
	mov r5, 0
	.label_154:
	mov r6, r5
	cmp r6, r2
	jl .label_157
	jmp .label_156
	.label_157:
	mov r6, r3
	add r6, 1
	shl r6, 3
	xor r3, r6
	mov r6, r3
	shr r6, 5
	xor r3, r6
	mov r6, r3
	shl r6, 2
	xor r3, r6
	mov r6, r3
	mov r7, 127
	and r6, r7
	.label_158:
	mov r7, r6
	cmp r7, 96
	jge .label_160
	.label_161:
	mov r7, r1
	add r7, r6
	ld r7, r7, 0
	cmp r7, 9
	jge .label_160
	jmp .label_159
	.label_160:
	mov r6, r3
	add r6, 1
	shl r6, 3
	xor r3, r6
	mov r6, r3
	shr r6, 5
	xor r3, r6
	mov r6, r3
	shl r6, 2
	xor r3, r6
	mov r6, r3
	mov r7, 127
	and r6, r7
	jmp .label_158
	.label_159:
	mov r7, r1
	add r7, r6
	ld r8, r7
	mov r9, 9
	add r8, r9
	st r8, r7
	mov r7, 299
	ld r7, r7, r6
	mov r8, r7
	mull r8, 12
	sub r6, r8
	mov r8, r7
	sub r8, 1
	mov r9, r6
	sub r9, 1
	mov r10, r7
	add r10, 1
	mov r11, r6
	add r11, 1
	mov r12, r7
	cmp r12, 0
	jg .label_163
	jmp .label_162
	.label_163:
	mov r12, r6
	cmp r12, 0
	jg .label_166
	jmp .label_165
	.label_166:
	mov r12, 97
	mov r13, r8
	mull r13, 12
	add r12, r13
	add r12, r9
	ld r13, r12
	mov r14, 1
	add r13, r14
	st r13, r12
	jmp .label_167
	.label_165:
	.label_167:
	mov r12, 97
	mov r13, r8
	mull r13, 12
	add r12, r13
	add r12, r6
	ld r13, r12
	mov r14, 1
	add r13, r14
	st r13, r12
	mov r12, r6
	cmp r12, 11
	jl .label_169
	jmp .label_168
	.label_169:
	mov r12, 97
	mull r8, 12
	add r12, r8
	mov r8, r12
	add r8, r11
	ld r12, r8
	mov r13, 1
	add r12, r13
	st r12, r8
	jmp .label_170
	.label_168:
	.label_170:
	jmp .label_164
	.label_162:
	.label_164:
	mov r8, r6
	cmp r8, 0
	jg .label_172
	jmp .label_171
	.label_172:
	mov r8, 97
	mov r12, r7
	mull r12, 12
	add r8, r12
	add r8, r9
	ld r12, r8
	mov r13, 1
	add r12, r13
	st r12, r8
	jmp .label_173
	.label_171:
	.label_173:
	mov r8, r6
	cmp r8, 11
	jl .label_175
	jmp .label_174
	.label_175:
	mov r8, 97
	mov r12, r7
	mull r12, 12
	add r8, r12
	add r8, r11
	ld r12, r8
	mov r13, 1
	add r12, r13
	st r12, r8
	jmp .label_176
	.label_174:
	.label_176:
	cmp r7, 7
	jl .label_178
	jmp .label_177
	.label_178:
	mov r7, r6
	cmp r7, 0
	jg .label_181
	jmp .label_180
	.label_181:
	mov r7, 97
	mov r8, r10
	mull r8, 12
	add r7, r8
	add r7, r9
	ld r8, r7
	mov r9, 1
	add r8, r9
	st r8, r7
	jmp .label_182
	.label_180:
	.label_182:
	mov r7, 97
	mov r8, r10
	mull r8, 12
	add r7, r8
	add r7, r6
	ld r8, r7
	mov r9, 1
	add r8, r9
	st r8, r7
	cmp r6, 11
	jl .label_184
	jmp .label_183
	.label_184:
	mov r6, 97
	mov r7, r10
	mull r7, 12
	add r6, r7
	add r6, r11
	ld r7, r6
	mov r8, 1
	add r7, r8
	st r7, r6
	jmp .label_185
	.label_183:
	.label_185:
	jmp .label_179
	.label_177:
	.label_179:
	mov r22, '.'
	call putchar
	.label_155:
	mov r6, r5
	add r5, 1
	jmp .label_154
	.label_156:
	mov r1, 97
	ld r2, r1
	mov r3, 9
	sub r2, r3
	st r2, r1
	mov r22, 0
	call set_cursor
	mov r22, 127
	call set_colour
	mov r25, 65409
	mov r24, 33153
	mov r23, 33153
	mov r22, 33279
	call __set_zero_char
	mov r1, 0
	.label_186:
	mov r2, r1
	cmp r2, 8
	jl .label_189
	jmp .label_188
	.label_189:
	mov r2, 40868
	mov r23, r2
	mov r22, 0
	call __send_raw
	.label_187:
	mov r2, r1
	add r1, 1
	jmp .label_186
	.label_188:
	mov r22, 0
	call set_cursor
	mov r5, 0
	mov r6, 0
	mov r3, 1
	.label_190:
	mov r1, 1
	cmp r1, 0
	je .label_191
	.label_192:
	mov r1, r5
	shl r1, 5
	add r1, r6
	mov r22, r1
	call set_cursor
	mov r22, 9
	call set_colour
	mov r1, 1
	mov r2, r5
	mull r2, 12
	add r1, r2
	ld r1, r1, r6
	mov r2, r1
	cmp r2, 'F'
	je .label_194
	jmp .label_193
	.label_194:
	mov r25, 127
	mov r24, 112
	mov r23, 28672
	mov r22, 28672
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_195
	.label_193:
	mov r2, r1
	cmp r2, 0
	je .label_197
	jmp .label_196
	.label_197:
	mov r25, 65409
	mov r24, 33153
	mov r23, 33153
	mov r22, 33279
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_198
	.label_196:
	mov r2, r1
	cmp r2, 'B'
	je .label_200
	jmp .label_199
	.label_200:
	mov r25, 39294
	mov r24, 32511
	mov r23, 53118
	mov r22, 20121
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_201
	.label_199:
	mov r2, r1
	cmp r2, '0'
	jne .label_203
	jmp .label_202
	.label_203:
	mov r22, r1
	call putchar
	jmp .label_204
	.label_202:
	mov r22, 144
	call set_colour
	mov r22, ' '
	call putchar
	.label_204:
	.label_201:
	.label_198:
	.label_195:
	call getchar
	mov r2, return_reg
	mov r7, r2
	mov r2, r5
	shl r2, 5
	add r2, r6
	mov r22, r2
	call set_cursor
	mov r2, r1
	cmp r2, 'F'
	je .label_206
	jmp .label_205
	.label_206:
	mov r22, 79
	call set_colour
	mov r25, 127
	mov r24, 112
	mov r23, 28672
	mov r22, 28672
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_207
	.label_205:
	mov r2, r1
	cmp r2, 0
	je .label_209
	jmp .label_208
	.label_209:
	mov r22, 127
	call set_colour
	mov r25, 65409
	mov r24, 33153
	mov r23, 33153
	mov r22, 33279
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_210
	.label_208:
	mov r2, r1
	cmp r2, 'B'
	je .label_212
	jmp .label_211
	.label_212:
	mov r22, 79
	call set_colour
	mov r25, 39294
	mov r24, 32511
	mov r23, 53118
	mov r22, 20121
	call __set_zero_char
	mov r22, 0
	call putchar
	jmp .label_213
	.label_211:
	mov r2, 289
	mov r8, r1
	sub r8, '0'
	add r2, r8
	ld r22, r2
	call set_colour
	mov r22, r1
	call putchar
	.label_213:
	.label_210:
	.label_207:
	mov r1, r7
	cmp r1, 'a'
	je .label_217
	jmp .label_214
	.label_217:
	mov r1, r6
	cmp r1, 0
	jg .label_215
	jmp .label_214
	.label_215:
	mov r1, r6
	sub r1, 1
	mov r6, r1
	jmp .label_216
	.label_214:
	mov r1, r7
	cmp r1, 'd'
	je .label_221
	jmp .label_218
	.label_221:
	mov r1, r6
	cmp r1, 11
	jl .label_219
	jmp .label_218
	.label_219:
	mov r1, r6
	add r1, 1
	mov r6, r1
	jmp .label_220
	.label_218:
	mov r1, r7
	cmp r1, 'w'
	je .label_225
	jmp .label_222
	.label_225:
	mov r1, r5
	cmp r1, 0
	jg .label_223
	jmp .label_222
	.label_223:
	mov r1, r5
	sub r1, 1
	mov r5, r1
	jmp .label_224
	.label_222:
	mov r1, r7
	cmp r1, 's'
	je .label_229
	jmp .label_226
	.label_229:
	mov r1, r5
	cmp r1, 7
	jl .label_227
	jmp .label_226
	.label_227:
	mov r1, r5
	add r1, 1
	mov r5, r1
	jmp .label_228
	.label_226:
	mov r1, r7
	cmp r1, 'f'
	je .label_231
	jmp .label_230
	.label_231:
	mov r1, 1
	mov r2, r5
	mull r2, 12
	add r1, r2
	ld r1, r1, r6
	cmp r1, 'F'
	je .label_234
	jmp .label_233
	.label_234:
	mov r1, 1
	mov r2, r5
	mull r2, 12
	add r1, r2
	add r1, r6
	mov r2, 0
	st r2, r1
	jmp .label_235
	.label_233:
	mov r1, 1
	mov r2, r5
	mull r2, 12
	add r1, r2
	ld r1, r1, r6
	cmp r1, 0
	je .label_237
	jmp .label_236
	.label_237:
	mov r1, 1
	mov r2, r5
	mull r2, 12
	add r1, r2
	add r1, r6
	mov r2, 'F'
	st r2, r1
	jmp .label_238
	.label_236:
	.label_238:
	.label_235:
	jmp .label_232
	.label_230:
	mov r1, r7
	cmp r1, 10
	je .label_240
	.label_242:
	mov r1, r7
	cmp r1, 'r'
	je .label_240
	jmp .label_239
	.label_240:
	cmp r3, 0
	je .label_243
	.label_244:
	mov r1, 97
	mov r2, r5
	mull r2, 12
	add r1, r2
	ld r1, r1, r6
	cmp r1, 9
	jge .label_247
	jmp .label_246
	.label_247:
	mov r1, 97
	mov r2, r5
	mull r2, 12
	add r1, r2
	add r1, r6
	ld r2, r1
	mov r3, 9
	sub r2, r3
	st r2, r1
	mov r1, 65535
	push r1
	push r6
	push r5
	call add_to_surrounding_cells
	add stack_pointer, 3
	jmp .label_248
	.label_246:
	.label_248:
	mov r3, 0
	jmp .label_245
	.label_243:
	.label_245:
	push r6
	push r5
	call sweep_cell
	add stack_pointer, 2
	ld r1, 298
	cmp r1, r4
	jge .label_250
	jmp .label_249
	.label_250:
	mov r22, 0
	call set_cursor
	mov r22, 2
	call set_colour
	mov r1, 490
	mov r22, r1
	call __print_char_array
	mov return_reg, 0
	jmp .exit_main
	jmp .label_251
	.label_249:
	.label_251:
	jmp .label_241
	.label_239:
	.label_241:
	.label_232:
	.label_228:
	.label_224:
	.label_220:
	.label_216:
	jmp .label_190
	.label_191:
.exit_main:
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2
	pop r1
	pop base_pointer
	add stack_pointer, 2
	hlt
__print_unsigned_int:
	test r22, r22
	jnz .__print_unsigned_int_not_zero
	mov r22, '0'
	st r22, term_print
	jmp .__print_unsigned_int_exit
.__print_unsigned_int_not_zero:
	mov r23, 4		; p = 4
.__print_unsigned_int_fixed_point:
	mulh r24, r22, 52429	; q = (n * 52429) >> 16
	shr r24, 3		; q >>= 3
	mul r25, r24, 10		; d*q
	sub r22, r25		; remainder = n - d*q
	st r22, r23, .__print_unsigned_int_buf		
	sub r23, 1		; p--;
	movf r22, r24		; n = q
	jnz .__print_unsigned_int_fixed_point

	add r23, 1
.__print_unsigned_int_print_int:
	ld r22, r23, .__print_unsigned_int_buf
	add r22, '0'
	st r22, term_print
	add r23, 1
	cmp r23, 5
	jne .__print_unsigned_int_print_int
	
.__print_unsigned_int_exit:
	ret
.__print_unsigned_int_buf:
	dw 0, 0, 0, 0, 0

__print_signed_int:
    cmp r22, 0
    jge .__print_signed_int_not_negative
    mov r23, '-'
    st r23, term_print
	xor r22, 65535
    add r22, 1
.__print_signed_int_not_negative:
    call __print_unsigned_int
    ret
    
__print_char_array:
    ld r23, r22
    test r23, r23
    jz __print_char_array_exit
    st r23, term_print
    add r22, 1
    jmp __print_char_array
__print_char_array_exit:
    ret

putchar:
    st r22, term_print
    ret

getchar:
    ld return_reg, term_input
    test return_reg, return_reg
    jz getchar
    ret

set_colour:
    st r22, term_colour
    ret

__send_raw:
    st r22, r23
    ret

__set_zero_char:
    exh r23, r0, r23
    mov r22, r23, r22
    st r22, term_print_e
    exh r25, r0, r25
    mov r24, r25, r24
    st r24, term_print_o
    ret


set_cursor:
    st r22, term_cursor
    ret

__scan_unsigned_int:
    mov r23, 0
__scan_unsigned_int_loop:
    call getchar
    st return_reg, term_print
    sub return_reg, '0'
    cmp return_reg, 9
    jg __scan_unsigned_int_not_digit
    cmp return_reg, 0
    jl __scan_unsigned_int_not_digit
    mull r23, 10
    add r23, return_reg
    jmp __scan_unsigned_int_loop
__scan_unsigned_int_not_digit:
    st r23, r22
    ret


