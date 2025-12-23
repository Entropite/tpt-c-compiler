local Node = require('node')
local Token = require('token')
local Operand = require('operand')
local util = require('util')
local Type = require('type')
local Diagnostics = require('diagnostics')
local Message = require('message')

-- Intermediate representation code generation

local IRVisitor = { tac = {["!global"]={}},
                    temp = 0,
                    global = 0,
                    label = 0,
                    global_data = {},
                    types = {["INT"]=1, ["CHAR"]=1, ["VOID"]=1, ["POINTER"]=1}, -- size of the types
                    global_method = {id = "!global"},
                    loop_labels = {},
                    case_labels = {}
                    }
IRVisitor.method = IRVisitor.global_method
local operand = {
    l=function(s, method) return Operand:new("l", IRVisitor:next_stack(s, method or IRVisitor.method)) end, -- local variable
    p=function(v) return Operand:new("p", v) end,                   -- parameter
    g=function(s, l) return Operand:new("g", IRVisitor:next_global(s, l)) end, -- global variable
    pr=function() return Operand:new("pr", IRVisitor:next_temp()) end,
    i=function(v) return Operand:new("i", v) end,                      -- immediate
    t=function() return Operand:new("t", IRVisitor:next_temp()) end,    -- temporary    
    r=function(v) return Operand:new("r", v) end,                        -- binded register
    lb=function() return Operand:new("i", string.format(".label_%d", IRVisitor:next_label())) end, --label
    vr=function() return Operand:new("vr", IRVisitor:next_temp()) end -- variable register (used for variables residing in registers), should not be confused with "virtual register"
}
IRVisitor.standard_function_arguments = {operand.r("r22")}
IRVisitor.RETURN_REG = operand.r("return_reg")
IRVisitor.STACK_POINTER = operand.r("stack_pointer")
IRVisitor.BASE_POINTER = operand.r("base_pointer")
IRVisitor.__index = IRVisitor

function IRVisitor:next_label()
    local temp = self.label
    self.label = self.label + 1
    return temp
end

function IRVisitor:next_stack(size, method)
    assert(method.local_size ~= nil, "Method local size is nil")
    local result = method.local_size
    method.local_size = result + size
    return result
end

function IRVisitor:next_temp()
    self.temp = self.temp + 1
    return self.temp
end

function IRVisitor:next_global(size, l)
    local temp = self.global
    -- Update global_data table with the initial data list
    if l then
        local data_entry = {idx=temp, list=l, next_entry=nil}

        if(self.global_data ~= nil) then
            self.global_data.next_entry = data_entry
        end

        self.global_data = data_entry
    end

    self.global = temp + size
    return temp
end

function IRVisitor:register_global_word(data, start)
    self.global_data[start.value] = data
end

function IRVisitor:sizeof(type)
    local size = 1
    if (type == nil) then
        return size
    end
    while(type ~= nil and type.kind == Type.KINDS["ARRAY"]) do
        size = size * type.length
        type = type.points_to
    end

    if(type.kind == Type.KINDS["STRUCT"] or type.kind == Type.KINDS["UNION"]) then
        return size * type.size
    end

    assert(type ~= nil, "Base type is nil")
    return self.types[Type.INVERTED_KINDS[type.kind]] * size
end


function IRVisitor:generate_ir_code(ast, symbol_table)
    local NODE_TYPES = Node.NODE_TYPES
    local TOKEN_TYPES = Token.TOKEN_TYPES
    local PLACE_TYPES = Operand.PLACE_TYPES
    local tac = self.tac
    local global_method = self.global_method
    local get_symbol = symbol_table.get_symbol
    local set_symbol = symbol_table.set_symbol
    local new_scope = symbol_table.new_scope
    local exit_scope = symbol_table.exit_scope

    local node_check = Node.node_check

    -- lvalue, in register = pr
    -- lvalue, not in register = l p g
    -- rvalue in register = t, r, vr
    -- rvalue not in register = i
    local lvalue_operands = {["l"]=1,["p"]=2,["g"]=3, ["pr"]=4, ["vr"]=5} -- has lvalue; may or may not have a register
    local mem_lvalue_operands = {["l"]=1, ["p"]=1, ["g"]=1, ["vr"]=1} -- has lvalue but doesn't have a register
    local reg_rvalue_operands = {["t"]=1, ["r"]=2, ["vr"]=3} -- has r value; has a register
    local rvalue_operands = {["i"]=1, ["t"]=1, ["r"]=1, ["vr"]=1} -- has r value without lvalue; may or may not have a register
    local aggregate_types = {["ARRAY"]=1, ["STRUCT"]=1, ["UNION"]=1}
    
    function emit_program(n)
        for _, child in ipairs(n) do
            emit_declaration(child)
        end
    end


    function load_operand_into_register(place)
        -- for idempotency
        if(place.type == "t") then
            return place
        end

        local next_reg = operand.t()
        emit_move(place, next_reg)

        return next_reg
    end

    

    function initialize_word(value, place)
        if(place.type == "g") then
            self:register_global_word(value, place)
        else
            emit_move(operand.i(value), place)
        end
    end

    function emit_static_initializer(n, start)
        local start = Operand:new(start.type, start.value)
        -- n is the initializer: either of type initializer_list or initializer
        if(node_check(n, "INITIALIZER")) then
            local element = n.value
            if(node_check(element, "INT")) then
                initialize_word(element.value, start)
            elseif(node_check(element, "CHARACTER")) then
                initialize_word(element.value, start)
            elseif(node_check(element, "STRING_LITERAL")) then
                register_string_literal(element, start)
            else           
                emit_assignment_expression(element)
                emit_move(element.place, start)
            end
        elseif(node_check(n, "INITIALIZER_LIST")) then
            for i, child in ipairs(n) do
                if(n.value_type.kind == Type.KINDS["ARRAY"]) then
                    child.value_type = n.value_type.points_to
                elseif(n.value_type.kind == Type.KINDS["STRUCT"]) then
                    child.value_type = n.value_type.members[i].type
                elseif(n.value_type.kind == Type.KINDS["UNION"]) then
                    child.value_type = Type.base("VOID")
                end
                emit_static_initializer(child, start)
                start = Operand:new(start.type, start.value + self:sizeof(child.value_type))
            end
        end
    end

    function register_string_literal(n, start)
        for i = 1, n.value_type.length do 
            local char = 0
            if(i <= #n.value) then
                char = string.format("%d", string.byte(string.sub(n.value, i, i)))
                --[[if(string.sub(n.value, i, i) < ' ') then
                    char = string.format("%d", string.byte(string.sub(n.value, i, i)))
                else
                    char = string.format("'%s'", string.sub(n.value, i, i))
                end]]
            end

            self:register_global_word(char, start)
            start = Operand:new(start.type, start.value + 1)
        end
    end

    function static_allocate_place(size)
        size = size or 1
        if(self.method.id == "!global") then
            return operand.g(size)
        else
            return operand.l(size)
        end
    end

    function compute_struct_layout(type)
        local offset = 0
        for i, member in ipairs(type.members) do
            member.offset = offset
            if(member.type.kind == Type.KINDS["STRUCT"]) then
                compute_struct_layout(member.type)
            elseif(member.type.kind == Type.KINDS["UNION"]) then
                compute_union_layout(member.type)
            end
            offset = offset + self:sizeof(member.type)
        end
        type.size = offset
        return type
    end

    function compute_union_layout(type)
        local size = 0
        for i, member in ipairs(type.members) do
            member.offset = 0
            if(member.type.kind == Type.KINDS["STRUCT"]) then
                compute_struct_layout(member.type)
            elseif(member.type.kind == Type.KINDS["UNION"]) then
                compute_union_layout(member.type)
            end
            size = math.max(size, self:sizeof(member.type))
        end
        type.size = size
        
        return type
    end

    function emit_struct_or_union_declaration(n)
        if(n.handle.type.kind == Type.KINDS["STRUCT"] and n.specifier.type_specifier.kind.declaration) then
            compute_struct_layout(n.handle.type)
        elseif(n.handle.type.kind == Type.KINDS["UNION"] and n.specifier.type_specifier.kind.declaration) then -- make sure the layout is only computed when the union is declared
            compute_union_layout(n.handle.type)
        end
    end

    function emit_declaration(n)
        assert(n.value_type ~= nil, "Value type is nil")
        --handle_name_definition_conflict(n.id)
        emit_struct_or_union_declaration(n)

        if(not n.declarator) then
            return
        end

        if(n.value_type.kind ~= Type.KINDS["FUNCTION"]) then

            local place = nil
            if(n.initializer) then
                local initializer_place = nil
                if(n.initializer.value and node_check(n.initializer.value, "STRING_LITERAL")) then
                    initializer_place = operand.g(n.initializer.value_type.length) -- string literals are stored in global memory
                else
                
                    if(n.specifier.storage_class.kind.value == "register") then
                        if(not aggregate_types[Type.INVERTED_KINDS[n.initializer.value_type.kind]]) then
                            initializer_place = operand.vr()
                        else
                            Diagnostics.submit(Message.error("Cannot store aggregate type in register", n.initializer.pos))
                        end
                    else
                        initializer_place = static_allocate_place(self:sizeof(n.initializer.value_type))
                    end
                end
                
                emit_static_initializer(n.initializer, initializer_place)
                if(node_check(n.initializer, "STRING_LITERAL") and n.value_type.kind == Type.KINDS["POINTER"]) then
                    place = static_allocate_place(1) -- pointer to object
                    if(self.method.id == "!global" or node_check(n.initializer.value, "STRING_LITERAL")) then -- String literal must be included even for local variables
                        initialize_word(initializer_place.value+1, place) -- +1 is to offset the initial jmp start instruction (poor design, might fix later)
                    else
                        local next_reg = operand.t()
                        table.insert(tac[self.method.id], {type="!get_address", target=n.handle.place, dest=next_reg}) 
                        emit_move(next_reg, n.handle.place)
                    end
                else
                    place=initializer_place -- object itself
                end
            else
                if(n.specifier.storage_class.kind.value == "register") then
                    place = operand.vr()
                else
                    place=static_allocate_place(self:sizeof(n.value_type)) -- no initializer
                end
            end
            n.handle.place = place
        else
            -- function definition
            assert(self.method.id == "!global", "Nested function definitions are not supported")

            n.handle.place = operand.i(n.id.id)
            n.handle.local_size = 0
            n.handle.id = n.id.id
            if(not n.block) then -- ignore function prototypes
                return
            end
            self.method = n.handle
            table.insert(tac, self.method.id)
            tac[self.method.id] = {}
            

            new_scope(self.method.id)

            
            for i, p in ipairs(n.declarator.direct_declarator.parameter_list or {}) do
                p.handle.place = operand.p(i-1)
            end

            if(n.block) then
                emit_block(n.block)
            else
                
            end
            exit_scope()
            self.method = global_method

        end
    end

    function emit_expression(n)
        for i = 1, #n do
            emit_assignment_expression(n[i])
        end
        
        n.place = n[#n].place
    end

    local symbol_to_operation_type = {
        ["+="] = "add",
        ["-="] = "sub",
        ["*="] = "mull",
        ["&="] = "and",
        ["|="] = "or",
        ["^="] = "xor",
        ["<<="] = "shl",
        [">>="] = "shr",
    }

    function d_assert(condition, message)
        if(not condition) then
            Diagnostics.submit(message)
        end
    end

    function emit_assignment_expression(n)
        if (n.lhs) then 
            emit_ternary_expression(n.lhs)
            emit_assignment_expression(n.rhs)
            if(n.op == "=") then
                n.place = emit_move(n.rhs.place, n.lhs.place) -- emit_move will return the source for optimization reasons
            elseif(n.op == "/=") then
                local lhs_place = n.lhs.place
                if(not reg_rvalue_operands[n.lhs.place.type]) then
                    lhs_place = load_operand_into_register(n.lhs.place)
                end
                local rhs_place = n.rhs.place
                if(not reg_rvalue_operands[n.rhs.place.type]) then
                    rhs_place = load_operand_into_register(n.rhs.place)
                end
                local quotient = emit_division(lhs_place, rhs_place)
                emit_move(quotient, n.lhs.place)
            elseif(n.op == "%=") then
                local lhs_place = n.lhs.place
                if(not reg_rvalue_operands[n.lhs.place.type]) then
                    lhs_place = load_operand_into_register(n.lhs.place)
                end
                local rhs_place = n.rhs.place
                if(not reg_rvalue_operands[n.rhs.place.type]) then
                    rhs_place = load_operand_into_register(n.rhs.place)
                end
                local _, remainder = emit_division(lhs_place, rhs_place)
                emit_move(remainder, n.lhs.place)
            else
                d_assert(symbol_to_operation_type[n.op], Message.internal_error("Unsupported assignment operator: " .. n.op, n.pos))
                local lhs_place = n.lhs.place
                local rhs_place = n.rhs.place
                if(not reg_rvalue_operands[n.lhs.place.type]) then
                    lhs_place = load_operand_into_register(n.lhs.place)
                end
                if(not reg_rvalue_operands[n.rhs.place.type]) then
                    rhs_place = load_operand_into_register(n.rhs.place)
                end
                local operation_type = symbol_to_operation_type[n.op]
                table.insert(tac[self.method.id], {type=operation_type, source=rhs_place, dest=lhs_place})
                if(lhs_place ~= n.lhs.place) then
                    emit_move(lhs_place, n.lhs.place)
                end
                n.place = lhs_place -- returns the destination
            end

        else
            emit_ternary_expression(n)
        end

    end

    function emit_ternary_expression(n)
        if(node_check(n, "TERNARY")) then
            local false_label = operand.lb()
            local end_label = operand.lb()
            -- This might blow up
            -- if it is too much trouble, don't simplify
            if(is_condition_simplifiable(n.condition)) then
                emit_simplified_condition(n.condition, false_label, end_label)
                n.place = load_operand_into_register(n.condition.place or operand.t())
            else
                emit_logical_or_expression(n.condition)
                n.place = load_operand_into_register(n.condition.place) -- n.condition will have a place
                table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})

                table.insert(tac[self.method.id], {type="je", target=false_label})
            end
            emit_assignment_expression(n.true_case)
            emit_move(n.true_case.place, n.place) -- should n.place be a t only?
            table.insert(tac[self.method.id], {type="jmp", target=end_label})
            table.insert(tac[self.method.id], {type="label", target=false_label})
            emit_logical_or_expression(n.false_case)
            emit_move(n.false_case.place, n.place)
            table.insert(tac[self.method.id], {type="label", target=end_label})
        else
            emit_logical_or_expression(n)
        end
    end

    function emit_logical_or_expression(n, outer_false_label, outer_end_label)
        if(node_check(n, "LOGICAL_OR_EXPRESSION")) then
            local true_label = operand.lb()
            local false_label = outer_false_label or operand.lb()
            local end_label = outer_end_label or operand.lb()
            for i = 1, #n do
                if(is_condition_simplifiable(n[i])) then
                    emit_simplified_condition(n[i], false_label, end_label)
                    table.insert(tac[self.method.id], {type="jmp", target=true_label})
                else
                    emit_logical_and_expression(n[i])
                    n.place = load_operand_into_register(n[i].place)
                    table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})
                    table.insert(tac[self.method.id], {type="jne", target=true_label})
                end
            end
            if(not outer_false_label or not outer_end_label) then
                table.insert(tac[self.method.id], {type="label", target=false_label})
                emit_move(operand.i(0), n.place)
                table.insert(tac[self.method.id], {type="jmp", target=end_label})
                table.insert(tac[self.method.id], {type="label", target=true_label})
                emit_move(operand.i(1), n.place)
                table.insert(tac[self.method.id], {type="label", target=end_label})
            else
                table.insert(tac[self.method.id], {type="label", target=true_label})
            end
        else
            emit_logical_and_expression(n)
        end
    end

    function emit_logical_and_expression(n, outer_false_label, outer_end_label)
        if(node_check(n, "LOGICAL_AND_EXPRESSION")) then
            local true_label = operand.lb()
            local false_label = outer_false_label or operand.lb()
            local end_label = outer_end_label or operand.lb()
            for i = 1, #n do
                if(is_condition_simplifiable(n[i])) then
                    emit_simplified_condition(n[i], false_label, end_label)
                else
                    emit_inclusive_or_expression(n[i])
                    n.place = load_operand_into_register(n[i].place)
                    table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})
                    table.insert(tac[self.method.id], {type="je", target=false_label})
                end
            end
            if(not outer_false_label or not outer_end_label) then
                n.place = n.place or operand.t()
                table.insert(tac[self.method.id], {type="label", target=true_label})
                emit_move(operand.i(1), n.place)
                table.insert(tac[self.method.id], {type="jmp", target=end_label})
                table.insert(tac[self.method.id], {type="label", target=false_label})
                emit_move(operand.i(0), n.place)
                table.insert(tac[self.method.id], {type="label", target=end_label})
            end
        else
            emit_inclusive_or_expression(n)
        end
    end

    function emit_inclusive_or_expression(n)
        if(node_check(n, "INCLUSIVE_OR_EXPRESSION")) then
            emit_inclusive_xor_expression(n[1])
            n.place = load_operand_into_register(n[1].place)
            for i = 2, #n do
                emit_inclusive_xor_expression(n[i])
                local next_reg = load_operand_into_register(n[i].place)
                table.insert(tac[self.method.id], {type="or", source=next_reg, dest=n.place})
            end
        else
            emit_inclusive_xor_expression(n)
        end
    end

    function emit_inclusive_xor_expression(n)
        if(node_check(n, "INCLUSIVE_XOR_EXPRESSION")) then
            emit_inclusive_and_expression(n[1])
            n.place = load_operand_into_register(n[1].place)
            for i = 2, #n do
                emit_inclusive_and_expression(n[i])
                local next_reg = load_operand_into_register(n[i].place)
                table.insert(tac[self.method.id], {type="xor", source=next_reg, dest=n.place})
            end
        else
            emit_inclusive_and_expression(n)
        end
    end

    function emit_inclusive_and_expression(n)
        if(node_check(n, "INCLUSIVE_AND_EXPRESSION")) then
            emit_equality_expression(n[1])
            n.place = load_operand_into_register(n[1].place)
            for i = 2, #n do
                emit_equality_expression(n[i])
                local next_reg = load_operand_into_register(n[i].place)
                table.insert(tac[self.method.id], {type="and", source=next_reg, dest=n.place})
            end
        else
            emit_equality_expression(n)
        end
    end

    function emit_equality_expression(n, outer_false_label, outer_end_label)
        if(node_check(n, "EQUALITY_EXPRESSION")) then
            emit_relational_expression(n[1])
            if(#n == 3 and outer_false_label and n[1].place.type == "vr") then
                n.place = n[1].place 
            else
                n.place = load_operand_into_register(n[1].place)
            end
            local next_reg = nil
            for i = 3, #n, 2 do
                emit_relational_expression(n[i])
                
                next_reg = (n[i].place.type == "i" or n[i].place.type == "vr") and n[i].place or load_operand_into_register(n[i].place)

                local false_label = outer_false_label or operand.lb()
                local end_label = outer_end_label or operand.lb()

                
                table.insert(tac[self.method.id], {type="cmp", first=n.place, second=next_reg})
                if(n[i - 1].type == TOKEN_TYPES['==']) then
                    table.insert(tac[self.method.id], {type="jne", target=false_label})
                else
                    table.insert(tac[self.method.id], {type="je", target=false_label})
                end
                if(not outer_false_label or not outer_end_label) then
                    emit_move(operand.i(1), n.place) -- true case
                    table.insert(tac[self.method.id], {type="jmp", target=end_label})
                    table.insert(tac[self.method.id], {type="label", target=false_label})
                    emit_move(operand.i(0), n.place)
                    table.insert(tac[self.method.id], {type="label", target=end_label})
                end
            end
        else
            emit_relational_expression(n)
        end
    end

    function emit_children(n, child_function)
        local place = nil
        for i, v in ipairs(n) do
            if(not v.place) then
                child_function(v)
            end

            if(v.place.type == 't') then
                place = v.place
            end
        end

        return place or operand.t()
    end



    function emit_relational_expression(n, outer_false_label, outer_end_label)
        if(node_check(n, "RELATIONAL_EXPRESSION")) then
            emit_shift_expression(n[1])
            if(#n == 3 and outer_false_label and n[1].place.type == "vr") then
                n.place = n[1].place 
            else
                n.place = load_operand_into_register(n[1].place)
            end
            local next_reg = nil
            for i = 3, #n, 2 do
                emit_shift_expression(n[i])
                
                next_reg = (n[i].place.type == "i" or n[i].place.type == "vr") and n[i].place or load_operand_into_register(n[i].place)
                
                local false_label = outer_false_label or operand.lb()
                local end_label = outer_end_label or operand.lb()

                
                table.insert(tac[self.method.id], {type="cmp", first=n.place, second=next_reg})
                if(n[i - 1].type == TOKEN_TYPES['<']) then
                    table.insert(tac[self.method.id], {type=n.value_type.signed and "jge" or "jae", target=false_label})
                elseif(n[i - 1].type == TOKEN_TYPES['<=']) then
                    table.insert(tac[self.method.id], {type=n.value_type.signed and "jg" or "ja", target=false_label})
                elseif(n[i - 1].type == TOKEN_TYPES['>']) then
                    table.insert(tac[self.method.id], {type=n.value_type.signed and "jle" or "jbe", target=false_label})
                elseif(n[i - 1].type == TOKEN_TYPES['>=']) then
                    table.insert(tac[self.method.id], {type=n.value_type.signed and "jl" or "jb", target=false_label})
                end
                if(not outer_false_label or not outer_end_label) then
                    emit_move(operand.i(1), n.place) -- true case
                    table.insert(tac[self.method.id], {type="jmp", target=end_label})
                    table.insert(tac[self.method.id], {type="label", target=false_label})
                    emit_move(operand.i(0), n.place)
                    table.insert(tac[self.method.id], {type="label", target=end_label})
                end
            end
        else
            emit_shift_expression(n)
        end
    end

    function emit_shift_expression(n)
        if(node_check(n, "SHIFT_EXPRESSION")) then
            emit_sum_expression(n[1])
            n.place = load_operand_into_register(n[1].place)
            local next_reg = operand.t()
            for i = 3, #n, 2 do
                emit_sum_expression(n[i])
                if(not (reg_rvalue_operands[n[i].place.type] or n[i].place.type == "i")) then
                    emit_move(n[i].place, next_reg)
                else
                    next_reg = n[i].place
                end
                if(n[i - 1].type == TOKEN_TYPES['<<']) then
                    table.insert(tac[self.method.id], {type="shl", source=next_reg, dest=n.place})
                else -- logical right shift
                    table.insert(tac[self.method.id], {type="shr", source=next_reg, dest=n.place})
                end
            end
        else
            emit_sum_expression(n)
        end
    end


    -- Copies the rvalue associated with source into the rvalue associated with dest
    -- t1 to t2 -> mov t2, t1
    -- t to vr -> mov vr, t
    -- t to g -> st t, g
    -- t to l -> st t, l
    -- t to p -> st t, p
    -- t to pr -> st t, pr
    -- g to t -> ld t, g
    -- l to t -> ld t, l
    -- p to t -> ld t, p
    -- pr to t -> ld t, pr
    -- vr to t -> mov t, vr
    
    -- i to t -> mov t, i
    -- i to g -> mov t, i; st t, g
    -- ...
    -- pr1 to pr2 -> ld pr3, pr1; st pr3, pr2 --> pr is used as the temp since emit_dereference always returns a pr
    -- l1 to l2 -> ld pr, l1; st pr, l2
    -- 
    function emit_move(source, dest)
        
        assert(dest.type ~= "i", "destination cannot be an immediate")
        if(source == dest) then
            return
        end

        local is_source_mem = not rvalue_operands[source.type]
        local is_dest_mem = not rvalue_operands[dest.type]

        if(source.type == "i" and is_dest_mem) then
            source = load_operand_into_register(source)
        end


        if(not is_source_mem and not is_dest_mem) then
            table.insert(tac[self.method.id], {type="mov", source=source, dest=dest})
        elseif(not is_source_mem and is_dest_mem) then
            table.insert(tac[self.method.id], {type="st", source=source, dest=dest})
        elseif(is_source_mem and not is_dest_mem) then
            table.insert(tac[self.method.id], {type="ld", source=source, dest=dest})
        else
            -- source and dest are both memory based operands
            local t = load_operand_into_register(source) -- copy source and then store it
            emit_move(t, dest)
        end

        return source
    end


    function emit_block(n)
        for i, s in ipairs(n) do
            emit_statement(s)
        end
    end

    function emit_statement(n)
        if(n.child.type == NODE_TYPES["DECLARATION"]) then
            if(n.child.specifier.storage_class.kind.value == "static") then
                local temp_method = self.method
                self.method = self.global_method
                emit_declaration(n.child)
                self.method = temp_method
            else
                emit_declaration(n.child)
            end
        elseif(n.child.type == NODE_TYPES["IF"]) then
            emit_if(n.child)
        elseif(n.child.type == NODE_TYPES["RETURN"]) then
            emit_return(n.child)
        elseif(n.child.type == NODE_TYPES["BLOCK"]) then
            emit_block(n.child)
        elseif(n.child.type == NODE_TYPES["FOR"]) then
            emit_for(n.child)
        elseif(n.child.type == NODE_TYPES["BREAK"]) then
            emit_break(n.child)
        elseif(n.child.type == NODE_TYPES["WHILE"]) then
            emit_while(n.child)
        elseif(n.child.type == NODE_TYPES["CONTINUE"]) then
            emit_continue(n.child)
        elseif(node_check(n.child, "SWITCH")) then
            emit_switch(n.child)
        elseif(node_check(n.child, "CASE")) then
            emit_case(n.child)
        elseif(node_check(n.child, "DEFAULT")) then
            emit_default(n.child)
        elseif(node_check(n.child, "EMPTY_STATEMENT")) then
            --nothing
        else
            emit_expression(n.child)
        end
    end

    function emit_case(n)
        emit_primary_expression(n.value)
        if(n.value.place.type ~= "i") then
            Diagnostics.submit(Message.error("Case values must be constants", n.value.pos))
        end

        local true_label = operand.lb()
        table.insert(self.case_labels[#self.case_labels], {value=n.value.place, target=true_label})
        table.insert(tac[self.method.id], {type="label", target=true_label})
        emit_statement(n.statement)
    end

    function emit_default(n)
        local default_label = operand.lb()
        self.case_labels[#self.case_labels].default = default_label
        table.insert(tac[self.method.id], {type="label", target=default_label})
        emit_statement(n.statement)
    end

    function emit_switch(n)
        emit_expression(n.condition)
        n.place = load_operand_into_register(n.condition.place)
        local end_label = operand.lb()
        local mark = #tac[self.method.id] + 1 -- horribly inefficient, will fix later
        table.insert(self.case_labels, {})
        table.insert(self.loop_labels, {update_lb=end_label, end_lb=end_label})
        emit_block(n.block)

        -- handle the case labels
        for _, labels in ipairs(self.case_labels[#self.case_labels]) do
            table.insert(tac[self.method.id], mark, {type="cmp", first=n.place, second=labels.value})
            table.insert(tac[self.method.id], mark + 1, {type="je", target=labels.target})
            mark = mark + 2
        end
        if(self.case_labels[#self.case_labels].default) then
            table.insert(tac[self.method.id], mark, {type="jmp", target=self.case_labels[#self.case_labels].default})
        else
            table.insert(tac[self.method.id], mark, {type="jmp", target=end_label})
        end
        table.insert(tac[self.method.id], {type="label", target=end_label})
        table.remove(self.case_labels)
        table.remove(self.loop_labels)
    end

    function is_condition_simplifiable(n)
        return #n <= 3 and (node_check(n, "LOGICAL_AND_EXPRESSION") or (node_check(n, "RELATIONAL_EXPRESSION") or node_check(n, "EQUALITY_EXPRESSION")) or node_check(n, "LOGICAL_OR_EXPRESSION"))
    end

    function emit_simplified_condition(n, false_label, end_label)
        if(node_check(n, "RELATIONAL_EXPRESSION")) then
            emit_relational_expression(n, false_label, end_label)
        elseif(node_check(n, "EQUALITY_EXPRESSION")) then
            emit_equality_expression(n, false_label, end_label)
        elseif(node_check(n, "LOGICAL_AND_EXPRESSION")) then
            emit_logical_and_expression(n, false_label, end_label)
        elseif(node_check(n, "LOGICAL_OR_EXPRESSION")) then
            emit_logical_or_expression(n, false_label, end_label)
        end
    end

    function emit_if(n)
        local false_label = operand.lb()
        local end_label = operand.lb()
        if(is_condition_simplifiable(n.condition[1])) then
            emit_simplified_condition(n.condition[1], false_label, end_label)
        else
            emit_expression(n.condition)
        end
        if(not is_condition_simplifiable(n.condition[1])) then
            n.place = load_operand_into_register(n.condition.place)
            table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})
            table.insert(tac[self.method.id], {type="je", target=false_label})
        end
        emit_statement(n.true_case)
        table.insert(tac[self.method.id], {type="jmp", target=end_label})
        table.insert(tac[self.method.id], {type="label", target=false_label})
        if(n.false_case) then
            emit_statement(n.false_case)
        end
        table.insert(tac[self.method.id], {type="label", target=end_label})
    end

    function emit_for(n)
        local start_label = operand.lb()
        local update_label = operand.lb()
        local end_label = operand.lb()
        table.insert(self.loop_labels, {update_lb=update_label, end_lb=end_label})
        if(node_check(n.initialization, "DECLARATION")) then
            emit_declaration(n.initialization)
        else
            emit_expression(n.initialization)
        end
        table.insert(tac[self.method.id], {type="label", target=start_label})
        -- For optimization purposes, the condition's false and end labels are associated with the for loop itself
        if(is_condition_simplifiable(n.condition[1])) then
            emit_simplified_condition(n.condition[1], end_label, end_label)
        else
            emit_expression(n.condition)
        end
        if(not is_condition_simplifiable(n.condition[1])) then
            n.place = load_operand_into_register(n.condition.place)
            table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})
            table.insert(tac[self.method.id], {type="je", target=end_label})
        end
        emit_statement(n.statement)
        table.insert(tac[self.method.id], {type="label", target=update_label})
        emit_expression(n.update)
        table.insert(tac[self.method.id], {type="jmp", target=start_label})
        table.insert(tac[self.method.id], {type="label", target=end_label})
        table.remove(self.loop_labels)
    end

    function emit_while(n)
        local start_label = operand.lb()
        local end_label = operand.lb()
        table.insert(self.loop_labels, {update_lb=start_label, end_lb=end_label})
        table.insert(tac[self.method.id], {type="label", target=start_label})
        if(is_condition_simplifiable(n.condition[1])) then
            emit_simplified_condition(n.condition[1], end_label, end_label)
        else
            emit_expression(n.condition)
        end
        if(not is_condition_simplifiable(n.condition[1])) then
            n.place = load_operand_into_register(n.condition.place)
            table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})
            table.insert(tac[self.method.id], {type="je", target=end_label})
        end
        emit_statement(n.statement)
        table.insert(tac[self.method.id], {type="jmp", target=start_label})
        table.insert(tac[self.method.id], {type="label", target=end_label})
        table.remove(self.loop_labels)
    end

    function emit_break(n)
        table.insert(tac[self.method.id], {type="jmp", target=self.loop_labels[#self.loop_labels].end_lb})
    end

    function emit_continue(n)
        table.insert(tac[self.method.id], {type="jmp", target=self.loop_labels[#self.loop_labels].update_lb})
    end

    function emit_return(n)
        emit_expression(n.value)
        
        if(lvalue_operands[n.value.place.type]) then
            n.value.place = load_operand_into_register(n.value.place)
        end

        table.insert(tac[self.method.id], {type="mov", source=n.value.place, dest=self.RETURN_REG})
        table.insert(tac[self.method.id], {type="jmp", target=operand.i(".exit_"..self.method.id)})

    end

    function emit_function_call(n)
        if(n.id == "print_num" or n.id == "printf") then
            emit_assignment_expression(n.args[1])
            if(lvalue_operands[n.args[1].place.type]) then
                table.insert(tac[self.method.id], {type="ld", source=n.args[1].place, dest=operand.r("r1")})
            else
                table.insert(tac[self.method.id], {type="mov", source=n.args[1].place, dest=operand.r("r1")})
            end
            table.insert(tac[self.method.id], {type="call", target=n.id})
        else
            emit_argument_list(n.args)
            table.insert(tac[self.method.id], {type="call", target=n.id})
            table.insert(tac[self.method.id], {type="add", source=operand.i(#n.args), dest=self.STACK_POINTER}) -- destroy stack frame
        end
    end

    function emit_argument_list(n, is_standard_function)
        for i=#n, 1, -1 do
            local a = n[i]
            emit_assignment_expression(a)
            if(not is_standard_function) then
                if(not reg_rvalue_operands[a.place.type] or a.place.type == "i") then
                    a.place = load_operand_into_register(a.place)
                end
                table.insert(tac[self.method.id], {type="push", target=a.place})
        
            else
                emit_move(a.place, self.standard_function_arguments[#self.standard_function_arguments - i + 1])
            end
        end
    end
        

    function emit_sum_expression(n)
        if(not node_check(n, "SUM_EXPRESSION")) then
            emit_term(n)
            return
        end
    
        emit_term(n[1])
        n.place = load_operand_into_register(n[1].place)
        for i = 3, #n, 2 do
            
            emit_term(n[i])
            -- term
            if(not (reg_rvalue_operands[n[i].place.type] or n[i].place.type == "i")) then
                n[i].place = load_operand_into_register(n[i].place)
            end

            if(n[i-1].type == TOKEN_TYPES['+']) then
                if(n.value_type.kind == Type.KINDS["POINTER"] or n.value_type.kind == Type.KINDS["ARRAY"]) then
                    emit_abstract_add(n[i].place, n.place, self:sizeof(n.value_type.points_to))
                else
                    table.insert(tac[self.method.id], {type="add", source = n[i].place, dest=n.place})
                end
            else
                
                table.insert(tac[self.method.id], {type="sub", source = n[i].place, dest=n.place})
            end
        end
    end


    -- computes dest += source * size
    -- size is i; dest is register operand; source is register operand or immediate
    -- source = t, dest = t -> mul t, size; add t, dest
    function emit_abstract_add(source, dest, size)

        assert(reg_rvalue_operands[dest.type], "dest must be an rvalue oriented operand in a register")
        assert(reg_rvalue_operands[source.type] or source.type == "i", "source must be rvalue oriented")

        if(source.type == "i") then
            source.value = source.value * size
        else
            if(size > 1) then
                if(source.type == "vr") then
                    source = load_operand_into_register(source)
                end
                table.insert(tac[self.method.id], {type="mull", source=operand.i(size), dest=source})
            end
        end
        table.insert(tac[self.method.id], {type="add", source=source, dest=dest})
    end

    function emit_term(n)
        if(not node_check(n, "MULTIPLICATIVE_EXPRESSION")) then
            emit_cast_expression(n)
            return
        end
        emit_cast_expression(n[1])
        if(#n > 1) then
            n.place = load_operand_into_register(n[1].place)
        else
            n.place = n[1].place
        end
        for i = 3, #n, 2 do
            
            emit_cast_expression(n[i])
        
            if(lvalue_operands[n[i].place.type]) then
                n[i].place = load_operand_into_register(n[i].place)
            end

            if(n[i-1].type == TOKEN_TYPES['*']) then
                table.insert(tac[self.method.id], {type="mull", source = n[i].place, dest=n.place})
            elseif(n[i-1].type == TOKEN_TYPES['/']) then
                if(n[i].place.type == "i") then
                    n[i].place = load_operand_into_register(n[i].place)
                end
                n.place = emit_division(n.place, n[i].place)
            elseif(n[i-1].type == TOKEN_TYPES['%']) then
                if(n[i].place.type == "i") then
                    n[i].place = load_operand_into_register(n[i].place)
                end
                _, n.place = emit_division(n.place, n[i].place)
            end
        end
    end

    -- performs unsigned division using binary long division
    function emit_division(dividend, divisor)
        assert(reg_rvalue_operands[dividend.type], "dividend must be an rvalue oriented operand in a register")
        assert(reg_rvalue_operands[divisor.type], "divisor must be an rvalue oriented operand in a register")

        local quotient = operand.t()
        local remainder = operand.t()
        local bit_index = operand.t()
        local loop_label = operand.lb()
        local temp = operand.t()
        local r_lt_d_label = operand.lb()
        local end_label = operand.lb()
        local instructions = {
            {type="mov", source=operand.i(0), dest=quotient},
            {type="mov", source=operand.i(0), dest=remainder},
            {type="mov", source=operand.i(15), dest=bit_index},
            {type="label", target=loop_label},
            {type="cmp", first=bit_index, second=operand.i(0)},
            {type="jl", target=end_label},
            {type="shl", source=operand.i(1), dest=remainder},
            {type="shr3", source=dividend, third=bit_index, dest=temp},
            {type="and", source=operand.i(1), dest=temp},
            {type="or", source=temp, dest=remainder},
            {type="cmp", first=remainder, second=divisor},
            {type="jl", target=r_lt_d_label},
            {type="sub", source=divisor, dest=remainder},
            {type="mov", source=operand.i(1), dest=temp},
            {type="shl", source=bit_index, dest=temp},
            {type="or", source=temp, dest=quotient},
            {type="label", target=r_lt_d_label},
            {type="sub", source=operand.i(1), dest=bit_index},
            {type="jmp", target=loop_label},
            {type="label", target=end_label}
        }

        for _, instruction in ipairs(instructions) do
            table.insert(tac[self.method.id], instruction)
        end

        return quotient, remainder
    end

    function emit_cast_expression(n)
        
        if(node_check(n, "CAST_EXPRESSION")) then
            emit_cast_expression(n.cast_expression)
            n.place = n.cast_expression.place
        else
            emit_unary_expression(n)
        end
    end

    function emit_unary_expression(n)
        if(node_check(n, "UNARY_EXPRESSION")) then
            if(n.operator == "++") then
                emit_unary_expression(n.child)
                local next_reg = rvalue_operands[n.child.place.type] and n.child.place or load_operand_into_register(n.child.place)
                emit_abstract_add(operand.i(1),next_reg, self:sizeof(n.child.value_type.points_to))
                emit_move(next_reg, n.child.place)
                n.place = next_reg
            elseif(n.operator == "--") then
                emit_unary_expression(n.child)
                local next_reg = rvalue_operands[n.child.place.type] and n.child.place or load_operand_into_register(n.child.place)
                emit_abstract_sub(operand.i(1),next_reg, self:sizeof(n.child.value_type.points_to))
                emit_move(next_reg, n.child.place)
                n.place = next_reg
            elseif(n.operator == "SIZEOF") then
                if(not node_check(n.child, "TYPE_NAME")) then
                    emit_cast_expression(n.child)
                end

                n.place = operand.i(self:sizeof(n.child.value_type))
            elseif(n.operator == "&") then
                emit_cast_expression(n.child)
                n.place = emit_address_of(n.child.place)
            elseif(n.operator == "*") then
                emit_cast_expression(n.child)
                n.place = emit_dereference(n.child.place)
            elseif(n.operator == "-") then
                emit_cast_expression(n.child)
                if(n.child.place.type == "i") then
                    n.place = copy_place(n.child.place)
                    n.place.value = 65536 - n.place.value
                else
                    n.place = load_operand_into_register(n.child.place)
                    table.insert(tac[self.method.id], {type="xor", source=operand.i(65535), dest=n.place}) -- take the two's complement
                    table.insert(tac[self.method.id], {type="add", source=operand.i(1), dest=n.place})
                end
            elseif(n.operator == "~") then
                emit_cast_expression(n.child)
                n.place = load_operand_into_register(n.child.place)
                table.insert(tac[self.method.id], {type="xor", source=operand.i(65535), dest=n.place})
            elseif(n.operator == "+") then
                emit_cast_expression(n.child)
                n.place = n.child.place
            elseif(n.operator == "!") then
                emit_cast_expression(n.child)
                n.place = load_operand_into_register(n.child.place)
                local false_label = operand.lb()
                local end_label = operand.lb()
                table.insert(tac[self.method.id], {type="cmp", first=n.place, second=operand.i(0)})
                table.insert(tac[self.method.id], {type="je", target=false_label})
                emit_move(operand.i(0), n.place)
                table.insert(tac[self.method.id], {type="jmp", target=end_label})
                table.insert(tac[self.method.id], {type="label", target=false_label})
                emit_move(operand.i(1), n.place)
                table.insert(tac[self.method.id], {type="label", target=end_label})
            else
                error()
            end
        else
            emit_postfix_expression(n)
        end
    end

    function emit_address_of(place)
        -- Retrieve the address of some memory location as an r value -> only lvalue types can be addressed
        local t = operand.t()
        if(mem_lvalue_operands[place.type]) then
            table.insert(tac[self.method.id], {type="!get_address", target=place, dest=t})
        elseif(place.type == "pr") then
            table.insert(tac[self.method.id], {type="mov", source=place, dest=t})
        elseif(place.type == "t") then
            return place -- for aggregate parameter passing
        else
            error()
        end
        return t
    end

    function emit_dereference(place)
        -- Dereferencing means loading the value of some memory pointed to by a pointer
        -- Thus, it can only act on lvalue types: g, p, l, and pr
        local pr = operand.pr()
        if(not rvalue_operands[place.type]) then
            table.insert(tac[self.method.id], {type="ld", source=place, dest=pr})
        elseif(place.type == "vr" or place.type == "t") then
            local pr = copy_place(load_operand_into_register(place))
            pr.type = "pr"
            return pr
        else
            print(place.type)
            print(tac[self.method.id][#tac[self.method.id]].type)
            error()
        end
        return pr
    end

    function emit_pointer_indexing(pointer, indexer, size)
        -- optimization for vr-vr pointer indexing
        if(pointer.type == "vr" and (indexer.type == "i" or (indexer.type == "vr" and size == 1))) then
            local pr = operand.pr()
            if(indexer.type == "i") then
                indexer = operand.i(indexer.value * size)
            end
            table.insert(tac[self.method.id], {type="add3", source=pointer, dest=pr, offset = indexer})
            return pr
        else
            local t = emit_dereference(pointer)
            return emit_indexing(t, indexer, size)
        end
    end

    -- shallow copy of a place
    function copy_place(place)
        return Operand:new(place.type, place.value)
    end


    -- indexing -> suppose n.place (indexed) is a t and operation.value.place (indexer) is an i -> return pr = t + i * sizeof(n.place) 
                    -- will always return a pr
                    -- ed = pr, er = i -> return pr = pr + er * sizeof(ed)
                    -- ed = g, er = i -> get address of g; add er * sizeof(ed) to the address
                    -- ed = l, er = i -> get address of l; add er * sizeof(ed) to the address
                    -- ed = g, er = pr -> get address of g; dereference pr to pr that acts like t; return pr = t + er * sizeof(ed)
                    -- ed = t, er = l -> dereference er to pr that acts like t; return pr = t + er * sizeof(ed)
    function emit_indexing(indexed, indexer, size)
        if(reg_rvalue_operands[indexed.type] and rvalue_operands[indexer.type]) then
            emit_abstract_add(indexer, indexed, size) -- indexed = indexer * size + indexed
            local pr = copy_place(indexed)
            pr.type = "pr"
            return pr
        elseif(lvalue_operands[indexed.type]) then
            if(indexer.type == "i") then
                return emit_offset_lvalue(indexer, indexed, size)
            end
            local t = emit_address_of(indexed)
            return emit_indexing(t, indexer, size)
        elseif(lvalue_operands[indexer.type]) then
            local t = copy_place(emit_dereference(indexer))
            t.type = "t"
            return emit_indexing(indexed, t, size)
        else
            error()
        end
    end


    function emit_postfix_expression(n)
        if(node_check(n, "POSTFIX_EXPRESSION")) then
            emit_primary_expression(n.primary_expression)
            n.place = n.primary_expression.place
            for i, operation in ipairs(n) do
                if(operation.type == "[") then
                    emit_expression(operation.value)
                    if(n.value_types[i-1].kind == Type.KINDS["POINTER"]) then
                        n.place = emit_pointer_indexing(n.place, operation.value.place, self:sizeof(n.value_types[i]))
                    else
                        n.place = emit_indexing(n.place, operation.value.place, self:sizeof(n.value_types[i]))
                    end
                elseif(operation.type == "(") then
                    emit_argument_list(operation.value, n.place.is_standard_function)

                    if(lvalue_operands[n.place.type]) then
                        n.place = load_operand_into_register(n.place)
                    end
                    table.insert(tac[self.method.id], {type="call", target=n.place}) -- fix this
                    if(not n.place.is_standard_function) then
                        table.insert(tac[self.method.id], {type="add", source=operand.i(#operation.value), dest=self.STACK_POINTER}) -- destroy stack frame
                    end
                    if(n.value_types[i].kind ~= Type.KINDS["VOID"]) then
                        n.place = operand.t()
                        emit_move(self.RETURN_REG, n.place)
                    end
                elseif(operation.type == "++") then
                    local next_reg = load_operand_into_register(n.place)
                    if(reg_rvalue_operands[n.place.type]) then
                        emit_abstract_add(operand.i(1), n.place, self:sizeof(n.value_types[i].points_to or n.value_types[i]))
                        n.place = next_reg
                    else
                        local temp_reg = operand.t()
                        emit_move(next_reg, temp_reg)
                        emit_abstract_add(operand.i(1), next_reg, self:sizeof(n.value_types[i].points_to or n.value_types[i]))
                        emit_move(next_reg, n.place)
                        n.place = temp_reg
                    end
                elseif(operation.type == ".") then
                    local member_type = n.value_types[i-1].members[operation.value.id].type
                    local pr = copy_place(n.place)
                    pr.type = "pr"
                    n.place = pr
                    n.place = emit_offset_lvalue(operand.i(n.value_types[i-1].members[operation.value.id].offset), n.place, 1)
                    if(member_type.kind == Type.KINDS["ARRAY"]) then -- Might remove
                        n.place = emit_address_of(n.place)
                    end
                    -- if(n.place.type ~= "pr") then
                    --     local next_reg = operand.pr()
                    --     table.insert(tac[self.method.id], {type="!get_address", target=n.place, dest=next_reg})
                    --     n.place = next_reg
                    -- end
                    -- if(n.value_types[i-1].members[operation.value.id].offset > 0) then
                    --     table.insert(tac[self.method.id], {type="add", source=operand.i(n.value_types[i-1].members[operation.value.id].offset), dest=n.place})
                    -- end
                elseif(operation.type == "->") then
                    -- dereference and then add the offset to the address
                    n.place = emit_dereference(n.place)
                    n.place = emit_offset_lvalue(operand.i(n.value_types[i-1].points_to.members[operation.value.id].offset), n.place, 1)
                    -- if(not reg_rvalue_operands[n.place.type] and n.place.type ~= "pr") then
                    --     local next_reg = operand.pr() -- ? can this be a pr?
                    --     table.insert(tac[self.method.id], {type="!get_address", target=n.place, dest=next_reg})
                    --     n.place = next_reg
                    -- end
                    
                    -- table.insert(tac[self.method.id], {type="ld", source=n.place, dest=n.place})
                    -- local offset = n.value_types[i-1].points_to.members[operation.value.id].offset
                    -- if(offset > 0) then
                    --     table.insert(tac[self.method.id], {type="add", source=operand.i(offset), dest=n.place})
                    -- end
                end
            end
        else
            emit_primary_expression(n)
        end
    end

    -- offset is i; place is lvalue
    function emit_offset_lvalue(offset, place, size)
        assert(lvalue_operands[place.type] or place.type == "i", "place must be an lvalue")
        assert(offset.type == "i", "offset must be an immediate value")
        if(place.type == "pr") then
            table.insert(tac[self.method.id], {type="add", source=offset, dest=place})
            return place
        else
            local mem_lvalue = copy_place(place)
            mem_lvalue.value = mem_lvalue.value + offset.value * size
            return mem_lvalue
        end
    end

    

    function emit_primary_expression(n)
        if(node_check(n, "INT")) then
            n.place = operand.i(n.value)
        elseif(node_check(n, "IDENTIFIER")) then
            local symbol = n.handle
            if(symbol) then
                if(aggregate_types[Type.INVERTED_KINDS[symbol.type.kind]]) then
                    n.place = emit_address_of(symbol.place)
                else
                    n.place = symbol.place
                end
            else
                error(string.format("Variable '%s' used before definition", n.value))
            end
        elseif(node_check(n, "CHARACTER")) then
            n.place = operand.i(n.value)
        elseif(node_check(n, "EXPRESSION")) then
            emit_expression(n);
        elseif(node_check(n, "STRING_LITERAL")) then
            local temp = operand.g(n.value_type.length)
            register_string_literal(n, temp)
            n.place = emit_address_of(temp) -- some r value registers can hold an address; however, the address cannot be used to store data except when used with an indexing operator
        else
            print(Node.INVERTED_NODE_TYPES[n.type])
            error()
        end
    end

    emit_program(ast)

    return self, symbol_table
end

return IRVisitor
