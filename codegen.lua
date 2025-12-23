local Operand = require("operand")
local Standard_Library = require("standard_library")
local Diagnostics = require("diagnostics")
local CodeGen = {
    size=8191,
    global_addr=1,
    symbol_table={},
    available_registers={},
    current_method="!global",
    register_count=21,
    ir = nil,
    optimized = true
    
}

for i=CodeGen.register_count, 1, -1 do
    table.insert(CodeGen.available_registers, i)
end


function CodeGen:as_memory(operand)
    if(operand.type == "g") then
        return self:as_global(operand)
    elseif(operand.type == "l") then
        return self:as_stack(operand)
    elseif(operand.type == "p") then
        return self:as_parameter(operand)
    elseif(operand.type == "i") then
        return operand.value
    elseif(operand.type == "pr" and operand.offset) then
        return self.as_reg(operand) .. ", " .. (operand.offset.type == "i" and operand.offset.value or self.as_reg(operand.offset))
    else
        return self.as_reg(operand)
    end
end

function CodeGen:get_offset_local_or_param(offset, local_size)
    if(offset.type == "l") then
        return operand.value + 1
    elseif(offset.type == "p") then
        return local_size + 2 + offset.value
    else
        error()
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
        if(type(operand.value) == "number") then
            return "r" .. operand.value
        else
            return operand.value
        end
    else
        return "r" .. operand.value
    end
end



function CodeGen:emit_get_address(symbol, dest)
    if(symbol.type == "g") then
        return {type="mov", source=Operand:new("g", symbol.value), dest=dest}
    elseif(symbol.type == "p") then
        return {type="add3", source=Operand:new("r", "base_pointer"), offset=Operand:new("i", self.current_method.local_size + 2 + symbol.value), dest=dest}
    elseif(symbol.type == "l") then
        return {type="add3", source=Operand:new("r", "base_pointer"), offset=Operand:new("i", symbol.value + 1), dest=dest}
    elseif(symbol.type == "pr") then
        return {type="mov", source=symbol, dest=dest}
    else
        print(symbol.type)
        error("Invalid symbol type")
    end
end

CodeGen.emission_map = {
    ["call"]=function(c) return string.format("%s %s", c.type, c.target.type == "i" and c.target.value or CodeGen.as_reg(c.target)) end,
    ["st"]=function(c) return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.source), CodeGen:as_memory(c.dest)) end,
    ["ld"]=function(c) return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.dest), CodeGen:as_memory(c.source)) end,
    ["push"]=function(c) return string.format("%s %s", c.type, CodeGen.as_reg(c.target)) end,
    ["pop"]=function(c) return string.format("%s %s", c.type, CodeGen.as_reg(c.target)) end,
    ["ret"]=function(c) return c.type end,
    ["label"]=function(c) return c.target.value..":" end,
    ["cmp"]=function(c) return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.first), c.second.type == "i" and c.second.value or CodeGen.as_reg(c.second)) end,
    ["nop"]=function(c) return c.type end,
    ["add3"]=function(c) return string.format("%s %s, %s, %s", "add", CodeGen.as_reg(c.dest), c.source.type == "i" and c.source.value or CodeGen.as_reg(c.source), c.offset.type == "i" and c.offset.value or CodeGen.as_reg(c.offset)) end, -- might remove this later since the __index metamethod can handle 3 operand instructions
    ["ldoffset"]=function(c) return string.format("%s %s, %s, %s", "ld", CodeGen.as_reg(c.dest), CodeGen.as_reg(c.source), c.offset.type == "i" and c.offset.value or CodeGen.as_reg(c.offset)) end
}


setmetatable(CodeGen.emission_map, {
    __index=function(t, x)
                return function(c) 
                    if(string.sub(c.type, #c.type, #c.type) == "3") then
                        return string.format("%s %s, %s, %s", string.sub(c.type, 1, #c.type - 1), CodeGen.as_reg(c.dest), CodeGen.as_reg(c.source), c.third.type == "i" and c.third.value or CodeGen.as_reg(c.third))
                    elseif(string.sub(c.type, 1, 1) == "j") then
                        return string.format("%s %s", c.type, c.target.value)
                    else
                        return string.format("%s %s, %s", c.type, CodeGen.as_reg(c.dest), c.source.type == "i" and c.source.value or CodeGen:as_memory(c.source)) 
                    end
                end
    end                                              
})

function CodeGen:build_global_data_section()
    if self.ir == nil or self.ir.global == 0 then
        return ""
    end

    local data_section = {}
    for i=0, self.ir.global - 1 do
        if self.ir.global_data[i] ~= nil then
            table.insert(data_section, self.ir.global_data[i])
        else
            table.insert(data_section, 0)
        end
    end

    return "dw " .. table.concat(data_section, ", ")
end

function CodeGen:generate(code, symbol_table)
    self.symbol_table = symbol_table
    self.ir = code
    gen = [[
%include "common"

%define return_reg r31
%define stack_pointer r30
%define base_pointer r29
%define term_reg r28
%define return_addr_reg r27

; Initialization and defining basic macros, most of this is the same as what LBPHacker did for his demo
%define term_base 0x9F80

%eval term_input  term_base 0x00 +
%eval term_raw    term_base 0x04 +
%eval term_single term_base 0x05 +
%eval term_print  term_base 0x25 +
%eval term_term   term_base 0x35 +
%eval term_hrange term_base 0x42 +
%eval term_vrange term_base 0x43 +
%eval term_cursor term_base 0x44 +
%eval term_nlchar term_base 0x45 +
%eval term_colour term_base 0x46 +


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
    ]] .. self:build_global_data_section() .. [[

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
    mov stack_pointer,]] .. self.size .. "\n" -- the stack decrements before storing a value, so the stack will initially overlap with the global storage

    -- handle global code
    self:lower_abstract_instructions(code.tac["!global"])
    if(self.optimized) then
        self:allocate_registers(code.tac["!global"])
        self:peephole(code.tac["!global"])
    end
    for i, c in ipairs(code.tac["!global"]) do
        gen = gen .. "\t" .. self.emission_map[c.type](c) .. "\n"
        
    end

    code.tac["!global"] = nil
    if(code.tac["main"] ~= nil) then
        gen = gen .. "\tjmp main\n"
    else
        gen = gen .. "\thlt\n"
    end
    -- handle method code
    for _, method_id in ipairs(code.tac) do
        c = code.tac[method_id]
        self.current_method = self.symbol_table.get_symbol(method_id, symbol_table.ordinary)
        -- emit prologue
        method = self.symbol_table.get_symbol(method_id, symbol_table.ordinary)
        gen = gen .. method_id .. ":\n"
        if(method.local_size > 0) then
            gen = gen .. "\tsub stack_pointer, " .. method.local_size .. "\n"
        end
        gen = gen .. "\tpush base_pointer\n"
        gen = gen .. "\tmov base_pointer, stack_pointer\n"
        -- emit body
        local used_registers = nil
        self:lower_abstract_instructions(c)
        if(self.optimized) then
            used_registers =self:allocate_registers(c)
            
            self:peephole(c)
            for i, v in ipairs(used_registers) do
                gen = gen .. "\tpush r" .. v .. "\n"
            end
        end
        for i, c in ipairs(c) do
            assert(c.type ~= nil, "Nil instruction")
            gen = gen .. "\t" .. self.emission_map[c.type](c) .. "\n"
        end
        -- emit epilogue
        gen = gen .. ".exit_" .. method_id .. ":\n"
        if(used_registers ~= nil) then
            for i = #used_registers, 1, -1 do
                gen = gen .. "\tpop r" .. used_registers[i] .. "\n"
            end
        end
        gen = gen .. "\tpop base_pointer\n"
        if(method.local_size > 0) then
            gen = gen .. "\tadd stack_pointer, " .. method.local_size .. "\n"
        end
        if(method_id ~= "main") then
            gen = gen .. "\tret\n"
        else
            gen = gen .. "\thlt\n"
        end
    end

    -- print num + other util functions
    built_ins =string.gsub(Standard_Library.code, "%%(%d+)", {["1"]="r22", ["2"]="r23", ["3"]="r24", ["4"]="r25"})

    return gen .. built_ins
end

function CodeGen:tac_to_string(tac)
    return "\t" .. self.emission_map[tac.type](tac) .. "\n"
end

CodeGen.use_def_map = {
    ["st"]=function(c) return {c.dest, c.source}, {} end,
    ["ld"]=function(c) return {c.source}, {c.dest} end,
    ["push"]=function(c) return {c.target}, {} end,
    ["pop"]=function(c) return {}, {c.target} end,
    ["call"]=function(c) return {c.target}, {} end,
    ["add3"]=function(c) return {c.source, c.offset}, {c.dest} end,
    ["ldoffset"]=function(c) return {c.source, c.offset}, {c.dest} end,
    ["cmp"]=function(c) return {c.first, c.second}, {} end,
    ["add"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["sub"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["mull"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["shl"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["shr"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["shr3"]=function(c) return {c.source, c.third}, {c.dest} end,
    ["xor"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["and"]=function(c) return {c.source, c.dest}, {c.dest} end,
    ["or"]=function(c) return {c.source, c.dest}, {c.dest} end
}
setmetatable(CodeGen.use_def_map, {
    __index=function(t, x)
        return function(c) return {c.source}, {c.dest} end
    end
})

function CodeGen:build_basic_blocks(tac)
    local basic_blocks = {}
    local current_block = {start=1, id="!start", code={}, pred={}, succ={}}
    basic_blocks[#basic_blocks + 1] = current_block
    local block_map = {[current_block.id]=current_block}

    function new_block(pred, succ, id)
        id=id or "anon_block" .. #basic_blocks
        local new_block = {id=id, code={}, pred=pred, succ=succ}
        table.insert(basic_blocks, new_block)
        block_map[id] = new_block
        return new_block
    end

    for i, c in ipairs(tac) do
        c.index = i
        if(c.type == "label") then
            table.insert(current_block.succ, c.target.value)
            if(block_map[c.target.value] == nil) then
                current_block = new_block({current_block.id}, {}, c.target.value)
            else
                table.insert(block_map[c.target.value].pred, current_block.id)
                current_block = block_map[c.target.value]
            end
                -- always entering an empty block although previous jmps may have discovered it
                current_block.code = {c}
        elseif(c.type == "jmp") then
            table.insert(current_block.succ, c.target.value)
            if(block_map[c.target.value] == nil) then
                new_block({current_block.id}, {}, c.target.value)
            else
                table.insert(block_map[c.target.value].pred,current_block.id)
            end
            table.insert(current_block.code, c)
            current_block = new_block({}, {})
        elseif(string.sub(c.type, 1, 1) == "j") then
            table.insert(current_block.succ, c.target.value)
            -- conditional jump
            if(block_map[c.target.value] == nil) then
                new_block({current_block.id}, {}, c.target.value)
            else
                table.insert(block_map[c.target.value].pred, current_block.id)
            end
            table.insert(current_block.code, c)
            table.insert(current_block.succ, "anon_block" .. #basic_blocks)
            current_block = new_block({current_block.id}, {})
        else
            table.insert(current_block.code, c)
        end
    end

    return basic_blocks, block_map
end

local reg_operands = {["t"]=1, ["vr"]=1, ["pr"]=1}

function CodeGen:build_block_use_def(block)
    local def_seen = {}
    block.use = {}
    block.def = {}
    for i, c in ipairs(block.code) do
        local use, def = self:get_instruction_use_def(c)
        for k,v in pairs(use) do
            if(def_seen[k] == nil) then
                block.use[k] = v
            end
        end
        for k,v in pairs(def) do
            if(def_seen[k] == nil) then
                def_seen[k] = v
                block.def[k] = v
            end
        end
    end
end

function multi_union(sets)
    local union = {}
    for _, set in ipairs(sets) do
        for k, v in pairs(set) do
            union[k] = true
        end
    end
    return union
end

function difference(set1, set2)
    local diff = {}

    for k, v in pairs(set1) do
        if(set2[k] == nil) then
            diff[k] = true
        end
    end
    return diff
end

function equal(set1, set2)
    for k, v in pairs(set1) do
        if(set2[k] == nil) then
            return false
        end
    end
    for k, v in pairs(set2) do
        if(set1[k] == nil) then
            return false
        end
    end
    return true
end

function CodeGen:liveness_block_analysis(blocks)
    local changed = true

    while(changed) do
        changed = false
        for name, block in pairs(blocks) do
            local old_in = block.live_in or {}
            local old_out = block.live_out or {}

            local succ_ins = {}
            for _, succ in ipairs(block.succ) do
                table.insert(succ_ins, blocks[succ].live_in)
            end
            block.live_out = multi_union(succ_ins)
            block.live_in = multi_union({block.use, difference(block.live_out, block.def)})
            if(not(equal(old_in, block.live_in) and equal(old_out, block.live_out))) then
                changed = true
            end
        end
    end
end

function copy_set(s)
    local copy = {}
    for k, v in pairs(s) do
        copy[k] = v
    end
    return copy
end

function CodeGen:compute_per_instruction_liveness(block)
    block.per_instruction_live_in = {}
    block.per_instruction_live_out = {}
    if(#block.code == 0) then
        return
    end
    local live = copy_set(block.live_out)
    for i = #block.code, 1, -1 do
        block.per_instruction_live_out[i] = copy_set(live)
        local use, def = self:get_instruction_use_def(block.code[i])
        live = multi_union({use, difference(live, def)}) or {}
        
        block.per_instruction_live_in[i] = copy_set(live)
    end
    if(not equal(block.live_in, block.per_instruction_live_in[1])) then
        error("Live in and per instruction live in are not equal")
    end
    if(not equal(block.live_out, block.per_instruction_live_out[#block.code])) then
        error("Live out and per instruction live out are not equal")
    end
end

function CodeGen:build_interference_graph(blocks)
    local interference_graph = {}

    for i, block in ipairs(blocks) do
        for j = 1, #block.code do
            local use, def = self:get_instruction_use_def(block.code[j])
            for k1, v1 in pairs(def) do
                interference_graph[k1] = interference_graph[k1] or {}
                for k2, v2 in pairs(block.per_instruction_live_out[j]) do
                    assert(type(k1) == "number" and type(k2) == "number", "Invalid operands")
                    interference_graph[k1][k2] = true
                    interference_graph[k2][k1] = true
                end
            end
        end
    end

    return interference_graph
end

function CodeGen:get_instruction_use_def(ins)
    local use_list, def_list = self.use_def_map[ins.type](ins)
    local use_set = {}
    local def_set = {}
    for _, v in ipairs(use_list) do
        if(reg_operands[v.type]) then
            use_set[v.value] = true
        end
    end
    for _, v in ipairs(def_list) do
        if(reg_operands[v.type]) then
            def_set[v.value] = true
        end
    end
    return use_set, def_set
end

function CodeGen:colour_graph(graph)
    local colour_mapping = {}
    local max_colour = 0

    for reg, neighbours in pairs(graph) do
        local used = {}
        for n,_ in pairs(neighbours) do
            local c = colour_mapping[n]
            if c then used[c] = true end
        end

        local c = 1
        while used[c] do c = c + 1 end

        colour_mapping[reg] = c
        if c > max_colour then max_colour = c end
    end

    return colour_mapping
end






function CodeGen:allocate_registers(tac)

    local blocks, block_map = self:build_basic_blocks(tac)
    for i, block in ipairs(blocks) do
        self:build_block_use_def(block)
    end
    self:liveness_block_analysis(block_map)

    local sort_by_code_order = function(a, b)
        if(#a.code == 0) then
            return false
        elseif(#b.code == 0) then
            return true
        else
            return a.code[1].index < b.code[1].index
        end
    end

    table.sort(blocks, sort_by_code_order)

    for i, block in ipairs(blocks) do
        self:compute_per_instruction_liveness(block)
        -- if(#block.code > 0) then
        --     print("\n\n\n",block.id, block.code[1].index)
        --     for i, v in ipairs(block.pred) do
        --         print("\tpred", v)
        --     end
        --     for i, v in ipairs(block.succ) do
        --         print("\tsucc", v)
        --     end
        --     for j=1, #block.code do
        --         print("Index ", j, "\t", self:tac_to_string(block.code[j]))
        --         for k, v in pairs(block.per_instruction_live_in[j]) do
        --             print("per instruction live in\t", k)
        --         end
        --         for k, v in pairs(block.per_instruction_live_out[j]) do
        --             print("per instruction live ou\t", k)
        --         end
        --     end

        -- end
    end

    local interference_graph = self:build_interference_graph(blocks)

    -- for k, v in pairs(interference_graph) do
    --     print("Neighbours of", k)
    --     for k2, v2 in pairs(v) do
    --         print("\t", k2)
    --     end
    -- end


    local colour_mapping = self:colour_graph(interference_graph)

    for i, cx in ipairs(tac) do
        for j, operand in pairs(cx) do
            if(type(operand) == "table" and (operand.type == "t" or operand.type == "pr" or operand.type == "vr")) then
                
                assert(colour_mapping[operand.value] ~= nil, "Invalid operand")
                operand.value = colour_mapping[operand.value]
                operand.type = "r"
            end
        end
    end

    local used = {}
    local colour_list = {}
    for k, v in pairs(colour_mapping) do
        if(used[v] == nil) then
            table.insert(colour_list, v)
            used[v] = true
        end
    end

    return colour_list

end

function CodeGen:lower_abstract_instructions(tac)
    for i = #tac - 1, 1, -1 do
        local c = tac[i]
        if(c.type == "!get_address") then
            tac[i] = self:emit_get_address(c.target, c.dest)
        end
    end
end


function CodeGen:peephole(tac)
    -- Peephole optimization
    -- TODO: clean this up with some more general rules/algorithms

    local removals = 0
    local base_pointer = Operand:new("r", "base_pointer")
    for i = #tac - 1, 1, -1 do
        local c = tac[i]
        local nc = tac[i + 1]
        if(c.type == "mov" and c.source == c.dest) then
            table.remove(tac, i)
            removals = removals + 1
        elseif(c.type == "add3" and tac[i + 1].type == "ld" and c.dest == tac[i + 1].source and tac[i + 1].dest == tac[i + 1].source) then
            tac[i] = {type="ldoffset", source=c.source, dest=tac[i + 1].dest, offset=c.offset}
            table.remove(tac, i + 1)
            removals = removals + 1
        elseif(c.type == "mov" and nc.type == "ld" and c.dest == nc.source and nc.dest == nc.source) then
            tac[i]={type="ld", source=c.source, dest=nc.dest}
            table.remove(tac, i + 1)
            removals = removals + 1
        elseif(c.type == "add" and nc.type == "ld" and c.dest == nc.source and nc.dest == nc.source) then
            tac[i]={type="ldoffset", source=nc.source, dest=nc.dest, offset=c.source}
            table.remove(tac, i + 1)
            removals = removals + 1
        elseif(c.type == "mov" and nc.type == "add" and c.dest == nc.dest) then
            if(reg_operands[c.source.type]) then
                tac[i] = {type="add3", source = c.source, dest = nc.dest, offset = nc.source}
                table.remove(tac, i + 1)
                removals = removals + 1
            elseif(c.source.type == "i" and type(c.source.value) == "number" and nc.source.type == "i" and type(nc.source.value) == "number") then
                tac[i] = {type="mov", source = Operand:new("i", c.source.value + nc.source.value), dest = nc.dest}
                table.remove(tac, i + 1)
                removals = removals + 1
            end
        elseif(c.type == "add" and c.source.type == "i" and c.source.value == 0) then
            table.remove(tac, i)
            removals = removals + 1
        elseif(c.type == "add" and nc.type == "add" and (c.source.type == "l" or c.source.type == "p") and nc.source.type == "i" and c.dest == nc.dest) then
            tac[i] = {type="add3", source = base_pointer, dest = c.dest, offset = operand.i(get_offset_local_or_param(c.source.value, self.current_method.local_size) + nc.source.value)}
            table.remove(tac, i + 1)
            removals = removals + 1
        elseif(c.type == "add3" and nc.type == "add" and c.source.value == "base_pointer" and c.offset.type == "i" and nc.source.type == "i" and c.dest == nc.dest) then
            tac[i] = {type="add3", source = base_pointer, dest=c.dest, offset = Operand:new("i", c.offset.value + nc.source.value)}
            table.remove(tac, i + 1)
            removals = removals + 1
        end
        
    end
    --print("[OPTIMIZER] Removed", removals, "instructions")
end


return CodeGen