%include "common"

%define return_reg r31
%define stack_pointer r30
%define base_pointer r29
%define term_reg r28
%define return_addr_reg r27
%define zero_high_reg r26 ; the msb 16 bits are all 0, unlike r0

; Initialization and defining basic macros
%define term_base 40832
%define term_height 8
%define term_width 12
 
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
%eval term_plot    term_base 0x60 +


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
    mov zero_high_reg, zero_high_reg, return_addr_reg
    pop return_addr_reg
    jmp zero_high_reg
%endmacro

%macro mull x, y
    mul x, x, y
%endmacro

jmp init
global_data_section:
    dw 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 119, 121, 114, 124, 113, 116, 118, 117, 120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 75, 97, 98, 111, 111, 109, 33, 32, 89, 111, 117, 32, 108, 111, 115, 101, 33, 0, 35, 32, 111, 102, 32, 109, 105, 110, 101, 115, 10, 40, 54, 45, 49, 50, 41, 58, 32, 0, 10, 69, 110, 116, 101, 114, 32, 97, 10, 110, 117, 109, 98, 101, 114, 32, 116, 111, 10, 104, 101, 108, 112, 10, 114, 97, 110, 100, 111, 109, 105, 122, 101, 10, 40, 49, 45, 49, 48, 48, 41, 58, 32, 0, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 0, 89, 111, 117, 32, 119, 105, 110, 33, 0
init:
    mov term_reg, 0x25
    exh zero_high_reg, r0, r0
    mov zero_high_reg, zero_high_reg, 1                        
                 
    mov r1, { term_width 1 - 5 << }
    st r1, term_hrange
    mov r1, { term_height 1 - 5 << }
    st r1, term_vrange
    mov r1, 0x1000
    st r1, term_cursor
    mov r1, 0xF
    st r1, term_colour
    mov r1, 10
    st r1,  term_nlchar

start:
    mov stack_pointer,4095
	jmp __tptcc_fn_main
__tptcc_fn_show_bombs:
	push base_pointer
	mov base_pointer, stack_pointer
	push r1
	push r2
	push r3
	push r4
	mov r1, 0
	.label_0:
	mov r2, r1
	mov r3, 8
	cmp r2, r3
	jl .label_3
	jmp .label_2
	.label_3:
	mov r2, 0
	.label_4:
	mov r3, r2
	mov r4, 12
	cmp r3, r4
	jl .label_7
	jmp .label_6
	.label_7:
	mov r3, 97
	mov r4, r1
	mull r4, 12
	add r3, r4
	ld r3, r3, r2
	mov r4, 9
	cmp r3, r4
	jge .label_9
	jmp .label_8
	.label_9:
	mov r23, r2
	mov r22, r1
	call __tptcc_fn_set_cursor
	mov r23, 15
	mov r22, 12
	call __tptcc_fn_set_colour
	mov r25, 39294
	mov r24, 32511
	mov r23, 53118
	mov r22, 20121
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_10
	.label_8:
	.label_10:
	.label_5:
	mov r3, r2
	add r2, 1
	jmp .label_4
	.label_6:
	.label_1:
	mov r2, r1
	add r1, 1
	jmp .label_0
	.label_2:
.exit_show_bombs:
	pop r4
	pop r3
	pop r2
	pop r1
	pop base_pointer
	ret
__tptcc_fn_sweep_cell:
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
	mov r4, 9
	cmp r3, r4
	jge .label_12
	jmp .label_11
	.label_12:
	call __tptcc_fn_show_bombs
	mov r23, 0
	mov r22, 0
	call __tptcc_fn_set_cursor
	mov r22, 12
	call __tptcc_fn_set_text_colour
	mov r3, 395
	mov r22, r3
	call __tptcc_fn_print_char_array
	mov r22, 9
	call __tptcc_fn_set_text_colour
	mov r23, r2
	mov r22, r1
	call __tptcc_fn_set_cursor
	mov r22, 0
	call __tptcc_fn_putchar
	.label_14:
	mov r3, 1
	cmp r3, 0
	je .label_15
	.label_16:
	jmp .label_14
	.label_15:
	jmp .label_13
	.label_11:
	.label_13:
	add r3, base_pointer, 1
	mov r4, 0
	add r5, r3, 0
	st r1, r5
	add r1, r3, 1
	st r2, r1
	mov r1, 2
	add r3, r1
	.label_17:
	mov r1, r3
	add r2, base_pointer, 1
	cmp r1, r2
	jg .label_19
	jmp .label_18
	.label_19:
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
	mov r23, r2
	mov r22, r1
	call __tptcc_fn_set_cursor
	mov r7, 289
	add r7, r5
	ld r22, r7
	call __tptcc_fn_set_text_colour
	mov r22, r6
	call __tptcc_fn_putchar
	mov r6, r4
	add r4, 1
	cmp r5, r0
	je .label_21
	jmp .label_20
	.label_21:
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
	je .label_23
	.label_24:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, r0
	je .label_27
	.label_29:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	mov r10, 'F'
	cmp r9, r10
	je .label_27
	jmp .label_26
	.label_27:
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
	jmp .label_28
	.label_26:
	.label_28:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, r0
	je .label_31
	.label_33:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	mov r10, 'F'
	cmp r9, r10
	je .label_31
	jmp .label_30
	.label_31:
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
	jmp .label_32
	.label_30:
	.label_32:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, r0
	je .label_35
	.label_37:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	mov r10, 'F'
	cmp r9, r10
	je .label_35
	jmp .label_34
	.label_35:
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
	jmp .label_36
	.label_34:
	.label_36:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, r0
	je .label_39
	.label_41:
	mov r9, 1
	mov r10, r7
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	mov r10, 'F'
	cmp r9, r10
	je .label_39
	jmp .label_38
	.label_39:
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
	jmp .label_40
	.label_38:
	.label_40:
	mov r9, 1
	mov r10, r1
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, r0
	je .label_43
	.label_45:
	mov r9, 1
	mov r10, r1
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	mov r10, 'F'
	cmp r9, r10
	je .label_43
	jmp .label_42
	.label_43:
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
	jmp .label_44
	.label_42:
	.label_44:
	mov r6, 1
	mov r9, r1
	mull r9, 12
	add r6, r9
	ld r6, r6, r8
	cmp r6, r0
	je .label_47
	.label_49:
	mov r6, 1
	mov r9, r1
	mull r9, 12
	add r6, r9
	ld r6, r6, r8
	mov r9, 'F'
	cmp r6, r9
	je .label_47
	jmp .label_46
	.label_47:
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
	jmp .label_48
	.label_46:
	.label_48:
	mov r1, 1
	mov r6, r7
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	cmp r1, r0
	je .label_51
	.label_53:
	mov r1, 1
	mov r6, r7
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	mov r6, 'F'
	cmp r1, r6
	je .label_51
	jmp .label_50
	.label_51:
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
	jmp .label_52
	.label_50:
	.label_52:
	mov r1, 1
	mov r6, r5
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	cmp r1, r0
	je .label_55
	.label_57:
	mov r1, 1
	mov r6, r5
	mull r6, 12
	add r1, r6
	ld r1, r1, r2
	mov r6, 'F'
	cmp r1, r6
	je .label_55
	jmp .label_54
	.label_55:
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
	jmp .label_56
	.label_54:
	.label_56:
	jmp .label_25
	.label_23:
	mov r9, r1
	cmp r9, r0
	jg .label_59
	jmp .label_58
	.label_59:
	mov r9, r2
	cmp r9, r0
	jg .label_64
	jmp .label_61
	.label_64:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	cmp r9, r0
	je .label_66
	.label_68:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r6
	mov r10, 'F'
	cmp r9, r10
	je .label_66
	jmp .label_65
	.label_66:
	mov r9, 1
	jmp .label_67
	.label_65:
	mov r9, 0
	.label_67:
	cmp r9, 0
	je .label_61
	.label_62:
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
	jmp .label_63
	.label_61:
	.label_63:
	mov r9, r2
	mov r10, 11
	cmp r9, r10
	jl .label_72
	jmp .label_69
	.label_72:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	cmp r9, r0
	je .label_74
	.label_76:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r8
	mov r10, 'F'
	cmp r9, r10
	je .label_74
	jmp .label_73
	.label_74:
	mov r9, 1
	jmp .label_75
	.label_73:
	mov r9, 0
	.label_75:
	cmp r9, 0
	je .label_69
	.label_70:
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
	jmp .label_71
	.label_69:
	.label_71:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r2
	cmp r9, r0
	je .label_78
	.label_80:
	mov r9, 1
	mov r10, r5
	mull r10, 12
	add r9, r10
	ld r9, r9, r2
	mov r10, 'F'
	cmp r9, r10
	je .label_78
	jmp .label_77
	.label_78:
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
	jmp .label_79
	.label_77:
	.label_79:
	jmp .label_60
	.label_58:
	.label_60:
	mov r5, r1
	mov r9, 7
	cmp r5, r9
	jl .label_82
	jmp .label_81
	.label_82:
	mov r5, r2
	cmp r5, r0
	jg .label_87
	jmp .label_84
	.label_87:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r6
	cmp r5, r0
	je .label_89
	.label_91:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r6
	mov r9, 'F'
	cmp r5, r9
	je .label_89
	jmp .label_88
	.label_89:
	mov r5, 1
	jmp .label_90
	.label_88:
	mov r5, 0
	.label_90:
	cmp r5, 0
	je .label_84
	.label_85:
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
	jmp .label_86
	.label_84:
	.label_86:
	mov r5, r2
	mov r9, 11
	cmp r5, r9
	jl .label_95
	jmp .label_92
	.label_95:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r8
	cmp r5, r0
	je .label_97
	.label_99:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r8
	mov r9, 'F'
	cmp r5, r9
	je .label_97
	jmp .label_96
	.label_97:
	mov r5, 1
	jmp .label_98
	.label_96:
	mov r5, 0
	.label_98:
	cmp r5, 0
	je .label_92
	.label_93:
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
	jmp .label_94
	.label_92:
	.label_94:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r2
	cmp r5, r0
	je .label_101
	.label_103:
	mov r5, 1
	mov r9, r7
	mull r9, 12
	add r5, r9
	ld r5, r5, r2
	mov r9, 'F'
	cmp r5, r9
	je .label_101
	jmp .label_100
	.label_101:
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
	jmp .label_102
	.label_100:
	.label_102:
	jmp .label_83
	.label_81:
	.label_83:
	mov r5, r2
	cmp r5, r0
	jg .label_107
	jmp .label_104
	.label_107:
	mov r5, 1
	mov r7, r1
	mull r7, 12
	add r5, r7
	ld r5, r5, r6
	cmp r5, r0
	je .label_109
	.label_111:
	mov r5, 1
	mov r7, r1
	mull r7, 12
	add r5, r7
	ld r5, r5, r6
	mov r7, 'F'
	cmp r5, r7
	je .label_109
	jmp .label_108
	.label_109:
	mov r5, 1
	jmp .label_110
	.label_108:
	mov r5, 0
	.label_110:
	cmp r5, 0
	je .label_104
	.label_105:
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
	jmp .label_106
	.label_104:
	.label_106:
	mov r5, 11
	cmp r2, r5
	jl .label_115
	jmp .label_112
	.label_115:
	mov r2, 1
	mov r5, r1
	mull r5, 12
	add r2, r5
	ld r2, r2, r8
	cmp r2, r0
	je .label_117
	.label_119:
	mov r2, 1
	mov r5, r1
	mull r5, 12
	add r2, r5
	ld r2, r2, r8
	mov r5, 'F'
	cmp r2, r5
	je .label_117
	jmp .label_116
	.label_117:
	mov r2, 1
	jmp .label_118
	.label_116:
	mov r2, 0
	.label_118:
	cmp r2, 0
	je .label_112
	.label_113:
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
	jmp .label_114
	.label_112:
	.label_114:
	.label_25:
	jmp .label_22
	.label_20:
	.label_22:
	jmp .label_17
	.label_18:
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
__tptcc_fn_add_to_surrounding_cells:
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
	mov r2, r5
	sub r2, 1
	mov r6, r2
	mov r2, r4
	add r2, 1
	mov r7, r2
	mov r2, r5
	add r2, 1
	mov r8, r2
	mov r2, r4
	cmp r2, r0
	jg .label_121
	jmp .label_120
	.label_121:
	mov r2, r5
	cmp r2, r0
	jg .label_124
	jmp .label_123
	.label_124:
	mov r2, 97
	mov r3, r1
	mull r3, 12
	add r2, r3
	add r2, r6
	ld r3, r2
	ld r9, base_pointer, 4
	add r3, r9
	st r3, r2
	jmp .label_125
	.label_123:
	.label_125:
	mov r2, 97
	mov r3, r1
	mull r3, 12
	add r2, r3
	add r2, r5
	ld r3, r2
	ld r9, base_pointer, 4
	add r3, r9
	st r3, r2
	mov r2, r5
	mov r3, 11
	cmp r2, r3
	jl .label_127
	jmp .label_126
	.label_127:
	mov r2, 97
	mull r1, 12
	add r2, r1
	add r2, r8
	ld r3, r2
	ld r1, base_pointer, 4
	add r3, r1
	st r3, r2
	jmp .label_128
	.label_126:
	.label_128:
	jmp .label_122
	.label_120:
	.label_122:
	mov r1, r5
	cmp r1, r0
	jg .label_130
	jmp .label_129
	.label_130:
	mov r1, 97
	mov r2, r4
	mull r2, 12
	add r1, r2
	add r1, r6
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_131
	.label_129:
	.label_131:
	mov r1, r5
	mov r2, 11
	cmp r1, r2
	jl .label_133
	jmp .label_132
	.label_133:
	mov r1, 97
	mov r2, r4
	mull r2, 12
	add r1, r2
	add r1, r8
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_134
	.label_132:
	.label_134:
	mov r1, r4
	mov r2, 7
	cmp r1, r2
	jl .label_136
	jmp .label_135
	.label_136:
	mov r1, r5
	cmp r1, r0
	jg .label_139
	jmp .label_138
	.label_139:
	mov r1, 97
	mov r2, r7
	mull r2, 12
	add r1, r2
	add r1, r6
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_140
	.label_138:
	.label_140:
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
	mov r2, 11
	cmp r1, r2
	jl .label_142
	jmp .label_141
	.label_142:
	mov r1, 97
	mov r2, r7
	mull r2, 12
	add r1, r2
	add r1, r8
	ld r2, r1
	ld r3, base_pointer, 4
	add r2, r3
	st r2, r1
	jmp .label_143
	.label_141:
	.label_143:
	jmp .label_137
	.label_135:
	.label_137:
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
__tptcc_fn_main:
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
	mov r4, r1
	mov r1, 413
	mov r22, r1
	call __tptcc_fn_print_char_array
	add r1, base_pointer, 1
	mov r22, r1
	call __tptcc_fn_scan_signed_int
	ld r5, base_pointer, 1
	mov r1, 96
	sub r1, r5
	mov r8, r1
	mov r22, 14
	call __tptcc_fn_set_text_colour
	mov r1, 433
	mov r22, r1
	call __tptcc_fn_print_char_array
	add r1, base_pointer, 2
	mov r22, r1
	call __tptcc_fn_scan_signed_int
	ld r1, base_pointer, 2
	xor r1, 65535
	add r1, 1
	mov r6, r1
	mov r22, 10
	call __tptcc_fn_putchar
	mov r23, 8
	mov r22, 8
	call __tptcc_fn_set_colour
	mov r23, 0
	mov r22, 7
	call __tptcc_fn_set_cursor
	mov r1, 477
	mov r22, r1
	call __tptcc_fn_print_char_array
	mov r23, 0
	mov r22, 7
	call __tptcc_fn_set_cursor
	mov r23, 10
	mov r22, 10
	call __tptcc_fn_set_colour
	mov r7, 0
	.label_144:
	mov r1, r7
	cmp r1, r5
	jl .label_147
	jmp .label_146
	.label_147:
	mov r1, r6
	add r1, 1
	shl r1, 3
	xor r6, r1
	mov r1, r6
	shr r1, 5
	xor r6, r1
	mov r1, r6
	shl r1, 2
	xor r6, r1
	mov r1, r6
	mov r2, 127
	and r1, r2
	.label_148:
	mov r2, r1
	mov r3, 96
	cmp r2, r3
	jge .label_150
	.label_151:
	mov r2, r4
	add r2, r1
	ld r2, r2, 0
	mov r3, 9
	cmp r2, r3
	jge .label_150
	jmp .label_149
	.label_150:
	mov r1, r6
	add r1, 1
	shl r1, 3
	xor r6, r1
	mov r1, r6
	shr r1, 5
	xor r6, r1
	mov r1, r6
	shl r1, 2
	xor r6, r1
	mov r1, r6
	mov r2, 127
	and r1, r2
	jmp .label_148
	.label_149:
	mov r2, r4
	add r2, r1
	ld r3, r2
	mov r9, 9
	add r3, r9
	st r3, r2
	mov r2, 299
	ld r2, r2, r1
	mov r3, r2
	mull r3, 12
	sub r1, r3
	mov r9, r1
	mov r1, r2
	sub r1, 1
	mov r3, r9
	sub r3, 1
	mov r10, r2
	add r10, 1
	mov r11, r9
	add r11, 1
	mov r12, r2
	cmp r12, r0
	jg .label_153
	jmp .label_152
	.label_153:
	mov r12, r9
	cmp r12, r0
	jg .label_156
	jmp .label_155
	.label_156:
	mov r12, 97
	mov r13, r1
	mull r13, 12
	add r12, r13
	add r12, r3
	ld r13, r12
	mov r14, 1
	add r13, r14
	st r13, r12
	jmp .label_157
	.label_155:
	.label_157:
	mov r12, 97
	mov r13, r1
	mull r13, 12
	add r12, r13
	add r12, r9
	ld r13, r12
	mov r14, 1
	add r13, r14
	st r13, r12
	mov r12, r9
	mov r13, 11
	cmp r12, r13
	jl .label_159
	jmp .label_158
	.label_159:
	mov r12, 97
	mull r1, 12
	add r12, r1
	mov r1, r12
	add r1, r11
	ld r12, r1
	mov r13, 1
	add r12, r13
	st r12, r1
	jmp .label_160
	.label_158:
	.label_160:
	jmp .label_154
	.label_152:
	.label_154:
	mov r1, r9
	cmp r1, r0
	jg .label_162
	jmp .label_161
	.label_162:
	mov r1, 97
	mov r12, r2
	mull r12, 12
	add r1, r12
	add r1, r3
	ld r12, r1
	mov r13, 1
	add r12, r13
	st r12, r1
	jmp .label_163
	.label_161:
	.label_163:
	mov r1, r9
	mov r12, 11
	cmp r1, r12
	jl .label_165
	jmp .label_164
	.label_165:
	mov r1, 97
	mov r12, r2
	mull r12, 12
	add r1, r12
	add r1, r11
	ld r12, r1
	mov r13, 1
	add r12, r13
	st r12, r1
	jmp .label_166
	.label_164:
	.label_166:
	mov r1, 7
	cmp r2, r1
	jl .label_168
	jmp .label_167
	.label_168:
	mov r1, r9
	cmp r1, r0
	jg .label_171
	jmp .label_170
	.label_171:
	mov r1, 97
	mov r2, r10
	mull r2, 12
	add r1, r2
	add r1, r3
	ld r2, r1
	mov r3, 1
	add r2, r3
	st r2, r1
	jmp .label_172
	.label_170:
	.label_172:
	mov r1, 97
	mov r2, r10
	mull r2, 12
	add r1, r2
	add r1, r9
	ld r2, r1
	mov r3, 1
	add r2, r3
	st r2, r1
	mov r1, r9
	mov r2, 11
	cmp r1, r2
	jl .label_174
	jmp .label_173
	.label_174:
	mov r1, 97
	mov r2, r10
	mull r2, 12
	add r1, r2
	add r1, r11
	ld r2, r1
	mov r3, 1
	add r2, r3
	st r2, r1
	jmp .label_175
	.label_173:
	.label_175:
	jmp .label_169
	.label_167:
	.label_169:
	mov r22, '.'
	call __tptcc_fn_putchar
	.label_145:
	mov r1, r7
	add r7, 1
	jmp .label_144
	.label_146:
	mov r1, 97
	ld r2, r1
	mov r3, 9
	sub r2, r3
	st r2, r1
	mov r23, 0
	mov r22, 0
	call __tptcc_fn_set_cursor
	mov r23, 15
	mov r22, 7
	call __tptcc_fn_set_colour
	mov r25, 65409
	mov r24, 33153
	mov r23, 33153
	mov r22, 33279
	call __tptcc_fn_set_zero_char
	mov r1, 0
	.label_176:
	mov r2, r1
	mov r3, 8
	cmp r2, r3
	jl .label_179
	jmp .label_178
	.label_179:
	mov r23, 40836
	mov r22, 0
	call __tptcc_fn_send_raw
	.label_177:
	mov r2, r1
	add r1, 1
	jmp .label_176
	.label_178:
	mov r23, 0
	mov r22, 0
	call __tptcc_fn_set_cursor
	mov r1, 0
	mov r2, 0
	mov r3, 1
	.label_180:
	mov r4, 1
	cmp r4, 0
	je .label_181
	.label_182:
	mov r23, r2
	mov r22, r1
	call __tptcc_fn_set_cursor
	mov r22, 9
	call __tptcc_fn_set_text_colour
	mov r4, 1
	mov r5, r1
	mull r5, 12
	add r4, r5
	ld r4, r4, r2
	mov r5, r4
	mov r6, 'F'
	cmp r5, r6
	je .label_184
	jmp .label_183
	.label_184:
	mov r25, 127
	mov r24, 112
	mov r23, 28672
	mov r22, 28672
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_185
	.label_183:
	mov r5, r4
	cmp r5, r0
	je .label_187
	jmp .label_186
	.label_187:
	mov r25, 65409
	mov r24, 33153
	mov r23, 33153
	mov r22, 33279
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_188
	.label_186:
	mov r5, r4
	mov r6, 'B'
	cmp r5, r6
	je .label_190
	jmp .label_189
	.label_190:
	mov r25, 39294
	mov r24, 32511
	mov r23, 53118
	mov r22, 20121
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_191
	.label_189:
	mov r5, r4
	mov r6, '0'
	cmp r5, r6
	jne .label_193
	jmp .label_192
	.label_193:
	mov r22, r4
	call __tptcc_fn_putchar
	jmp .label_194
	.label_192:
	mov r23, 0
	mov r22, 9
	call __tptcc_fn_set_colour
	mov r22, ' '
	call __tptcc_fn_putchar
	.label_194:
	.label_191:
	.label_188:
	.label_185:
	call __tptcc_fn_getchar
	mov r5, return_reg
	mov r23, r2
	mov r22, r1
	call __tptcc_fn_set_cursor
	mov r6, r4
	mov r7, 'F'
	cmp r6, r7
	je .label_196
	jmp .label_195
	.label_196:
	mov r23, 15
	mov r22, 12
	call __tptcc_fn_set_colour
	mov r25, 127
	mov r24, 112
	mov r23, 28672
	mov r22, 28672
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_197
	.label_195:
	mov r6, r4
	cmp r6, r0
	je .label_199
	jmp .label_198
	.label_199:
	mov r23, 15
	mov r22, 7
	call __tptcc_fn_set_colour
	mov r25, 65409
	mov r24, 33153
	mov r23, 33153
	mov r22, 33279
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_200
	.label_198:
	mov r6, r4
	mov r7, 'B'
	cmp r6, r7
	je .label_202
	jmp .label_201
	.label_202:
	mov r23, 15
	mov r22, 12
	call __tptcc_fn_set_colour
	mov r25, 39294
	mov r24, 32511
	mov r23, 53118
	mov r22, 20121
	call __tptcc_fn_set_zero_char
	mov r22, 0
	call __tptcc_fn_putchar
	jmp .label_203
	.label_201:
	mov r6, 289
	mov r7, r4
	sub r7, '0'
	add r6, r7
	ld r22, r6
	call __tptcc_fn_set_text_colour
	mov r22, r4
	call __tptcc_fn_putchar
	.label_203:
	.label_200:
	.label_197:
	mov r4, r5
	mov r6, 'a'
	cmp r4, r6
	je .label_207
	jmp .label_204
	.label_207:
	mov r4, r2
	cmp r4, r0
	jg .label_205
	jmp .label_204
	.label_205:
	sub r2, 1
	jmp .label_206
	.label_204:
	mov r4, r5
	mov r6, 'd'
	cmp r4, r6
	je .label_211
	jmp .label_208
	.label_211:
	mov r4, r2
	mov r6, 11
	cmp r4, r6
	jl .label_209
	jmp .label_208
	.label_209:
	add r2, 1
	jmp .label_210
	.label_208:
	mov r4, r5
	mov r6, 'w'
	cmp r4, r6
	je .label_215
	jmp .label_212
	.label_215:
	mov r4, r1
	cmp r4, r0
	jg .label_213
	jmp .label_212
	.label_213:
	sub r1, 1
	jmp .label_214
	.label_212:
	mov r4, r5
	mov r6, 's'
	cmp r4, r6
	je .label_219
	jmp .label_216
	.label_219:
	mov r4, r1
	mov r6, 7
	cmp r4, r6
	jl .label_217
	jmp .label_216
	.label_217:
	add r1, 1
	jmp .label_218
	.label_216:
	mov r4, r5
	mov r6, 'f'
	cmp r4, r6
	je .label_221
	jmp .label_220
	.label_221:
	mov r4, 1
	mov r5, r1
	mull r5, 12
	add r4, r5
	ld r4, r4, r2
	mov r5, 'F'
	cmp r4, r5
	je .label_224
	jmp .label_223
	.label_224:
	mov r4, 1
	mov r5, r1
	mull r5, 12
	add r4, r5
	add r4, r2
	mov r5, 0
	st r5, r4
	jmp .label_225
	.label_223:
	mov r4, 1
	mov r5, r1
	mull r5, 12
	add r4, r5
	ld r4, r4, r2
	cmp r4, r0
	je .label_227
	jmp .label_226
	.label_227:
	mov r4, 1
	mov r5, r1
	mull r5, 12
	add r4, r5
	add r4, r2
	mov r5, 'F'
	st r5, r4
	jmp .label_228
	.label_226:
	.label_228:
	.label_225:
	jmp .label_222
	.label_220:
	mov r4, r5
	mov r6, 10
	cmp r4, r6
	je .label_230
	.label_232:
	mov r4, r5
	mov r5, 'r'
	cmp r4, r5
	je .label_230
	jmp .label_229
	.label_230:
	cmp r3, 0
	je .label_233
	.label_234:
	mov r3, 97
	mov r4, r1
	mull r4, 12
	add r3, r4
	ld r3, r3, r2
	mov r4, 9
	cmp r3, r4
	jge .label_237
	jmp .label_236
	.label_237:
	mov r3, 97
	mov r4, r1
	mull r4, 12
	add r3, r4
	add r3, r2
	ld r4, r3
	mov r5, 9
	sub r4, r5
	st r4, r3
	mov r3, 65535
	push r3
	push r2
	push r1
	call __tptcc_fn_add_to_surrounding_cells
	add stack_pointer, 3
	jmp .label_238
	.label_236:
	.label_238:
	mov r3, 0
	jmp .label_235
	.label_233:
	.label_235:
	push r2
	push r1
	call __tptcc_fn_sweep_cell
	add stack_pointer, 2
	ld r4, 298
	cmp r4, r8
	jge .label_240
	jmp .label_239
	.label_240:
	mov r23, 0
	mov r22, 0
	call __tptcc_fn_set_cursor
	mov r22, 10
	call __tptcc_fn_set_text_colour
	mov r1, 490
	mov r22, r1
	call __tptcc_fn_print_char_array
	mov return_reg, 0
	jmp .exit_main
	jmp .label_241
	.label_239:
	.label_241:
	jmp .label_231
	.label_229:
	.label_231:
	.label_222:
	.label_218:
	.label_214:
	.label_210:
	.label_206:
	jmp .label_180
	.label_181:
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
__tptcc_fn_print_char_array:
    ld r23, r22
    test r23, r23
    jz .__print_char_array_exit
    st r23, term_reg, term_base
    add r22, 1
    jmp __tptcc_fn_print_char_array
.__print_char_array_exit:
    ret
__tptcc_fn_scan_signed_int:
    mov r23, 0
    call __tptcc_fn_getchar
    cmp return_reg, '-'
    jne __scan_unsigned_int_loop_signed_plugin
    st return_reg, term_reg, term_base
    call __tptcc_fn_scan_unsigned_int
    xor r23, 65535
    add r23, 1
    st r23, r22
    ret
__tptcc_fn_scan_unsigned_int:
    mov r23, 0
__scan_unsigned_int_loop:
    call __tptcc_fn_getchar
__scan_unsigned_int_loop_signed_plugin:
    st return_reg, term_reg, term_base
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

__tptcc_fn_send_raw:
    st r22, r23
    ret
__tptcc_fn_set_zero_char:
    exh r23, r0, r23
    mov r22, r23, r22
    st r22, term_print_e
    exh r25, r0, r25
    mov r24, r25, r24
    st r24, term_print_o
    ret
__tptcc_fn_getchar:
    ld return_reg, term_input
    test return_reg, return_reg
    jz __tptcc_fn_getchar
    ret
__tptcc_fn_putchar:
    st r22, term_reg, term_base
    ret
__tptcc_fn_set_colour:
    ; r22 = background, r23 = foreground
    shl r22, 4
    add r22, r23
    st r22, term_colour
    ret
__tptcc_fn_set_cursor:
    ; r22 = row, r23 = column
    shl r22, 5
    add r22, r23
    st r22, term_cursor
    ret
__tptcc_fn_set_text_colour:
    st r22, term_colour
    ret
