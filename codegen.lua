local Operand = require("operand")

local CodeGen = {
    size=2047,
    global_addr=0,
    symbol_table={},
    current_method="!global",
    
}


function CodeGen:as_memory(operand)
    if(operand.type == "g") then
        return self:as_global(operand)
    elseif(operand.type == "l") then
        return self:as_stack(operand)
    elseif(operand.type == "p") then
        return self:as_parameter(operand)
    end
end

function CodeGen:as_parameter(operand)
    return "base_pointer, " .. (self.current_method.local_size + operand.value + 2) -- +2 for the return address and base pointer
end

function CodeGen:as_global(operand)
    return self.global_addr + operand.value
end

function CodeGen:as_stack(operand)
    return "base_pointer, " .. (operand.value + 1)
end

function CodeGen.as_reg(operand)
    if(operand.type == "r") then
        return operand.value
    else
        return "r" .. operand.value
    end
end

CodeGen.emission_map = {
    ["call"]=function(c) return string.format("%s %s", c.type, c.target) end,
    ["st"]=function(c) return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.source), CodeGen:as_memory(c.dest)) end,
    ["ld"]=function(c) return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.dest), CodeGen:as_memory(c.source)) end,
    ["push"]=function(c) return string.format("%s %s", c.type, CodeGen.as_reg(c.target)) end,
    ["pop"]=function(c) return string.format("%s %s", c.type, CodeGen.as_reg(c.target)) end,
    ["ret"]=function(c) return c.type end,
    ["label"]=function(c) return c.value..":" end,
    ["jmp"]=function(c) return string.format("%s %s", c.type, c.target) end,
    ["call"]=function(c) return string.format("%s %s", c.type, c.target) end
}


setmetatable(CodeGen.emission_map, {
    __index=function(t, x)
                return function(c) 
                    return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.dest), c.source.type == "i" and c.source.value or CodeGen.as_reg(c.source)) 
                end
    end                                              
})


function CodeGen:generate(code)
    self.global_addr = self.size - code.global
    self.symbol_table = code.symbol_table
    gen = [[
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
    mov stack_pointer,]] .. (self.size - code.global) .. "\n" -- the stack decrements before storing a value, so the stack will initially overlap with the global storage

    -- handle global code
    for i, c in ipairs(code.tac["!global"]) do
        gen = gen .. "\t" .. self.emission_map[c.type](c) .. "\n"
    end

    code.tac["!global"] = nil
    gen = gen .. "\tjmp main\n"
    -- handle method code
    for method_id, c in pairs(code.tac) do
        self.current_method = self.symbol_table[method_id]
        -- emit prologue
        method = code.symbol_table[method_id]
        gen = gen .. method_id .. ":\n"
        gen = gen .. "\tsub stack_pointer, " .. method.local_size .. "\n"
        gen = gen .. "\tpush base_pointer\n"
        gen = gen .. "\tmov base_pointer, stack_pointer\n"
        -- emit body
    
        for i, c in ipairs(c) do
            gen = gen .. "\t" .. self.emission_map[c.type](c) .. "\n"
        end
        -- emit epilogue
        gen = gen .. ".exit_" .. method_id .. ":\n"
        gen = gen .. "\tpop base_pointer\n"
        gen = gen .. "\tadd stack_pointer, " .. method.local_size .. "\n"
        if(method_id ~= "main") then
            gen = gen .. "\tret\n"
        else
            gen = gen .. "\thlt\n"
        end
    end

    -- print num + other util functions
    gen = gen .. [[
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
	dw 0, 0, 0, 0, 0]]
    return gen
end

return CodeGen