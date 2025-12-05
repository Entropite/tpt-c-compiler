local Node = require('node')
local Token = require('token')
local Operand = require('operand')
local util = require('util')
local Type = require('type')
local serpent = require('serpent')
--local serpent = require('serpent')

-- Intermediate representation code generation

local IRVisitor = { tac = {["!global"]={}},
                    scope = {level=0, ["print_num"]={type=Type.func(Type.base("INT"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="print_num"}}},
                    symbol_table = {},
                    temp = 4,
                    global = 0,
                    global_data = {},
                    types = {["INT"]=1, ["CHAR"]=1, ["VOID"]=1, ["POINTER"]=1},
                    global_method = {id = "!global"},
                    }
IRVisitor.current_scope = IRVisitor.scope
IRVisitor.method = IRVisitor.global_method
local operand = {
    l=function(s, method) return Operand:new("l", IRVisitor:next_stack(s, method or IRVisitor.method)) end, -- local variable
    p=function(v) return Operand:new("p", v) end,                   -- parameter
    g=function(s, l) return Operand:new("g", IRVisitor:next_global(s, l)) end, -- global variable
    pr=function() return Operand:new("pr", IRVisitor:next_temp()) end,
    i=function(v) return Operand:new("i", v) end,                      -- immediate
    t=function() return Operand:new("t", IRVisitor:next_temp()) end,    -- temporary    
    r=function(v) return Operand:new("r", v) end                        -- binded register
}
IRVisitor.standard_function_arguments = {operand.r("r1")}
IRVisitor.RETURN_REG = operand.r("return_reg")
IRVisitor.STACK_POINTER = operand.r("stack_pointer")
IRVisitor.BASE_POINTER = operand.r("base_pointer")
IRVisitor.__index = IRVisitor

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

    assert(type ~= nil, "Base type is nil")
    return self.types[Type.INVERTED_KINDS[type.kind]] * size
end


function IRVisitor:generate_ir_code(ast)
    local NODE_TYPES = Node.NODE_TYPES
    local TOKEN_TYPES = Token.TOKEN_TYPES
    local PLACE_TYPES = Operand.PLACE_TYPES
    local tac = self.tac
    local symbol_table = self.symbol_table
    local current_scope = self.current_scope
    local global_method = self.global_method

    local node_check = Node.node_check

    memory_operands = {["l"]=1,["p"]=2,["g"]=3, ["pr"]=4}
    register_operands = {["t"]=1, ["r"]=2}
    
    function emit_program(n)
        for _, child in ipairs(n) do
            emit_declaration(child)
        end
    end


    function load_operand_into_register(place)
        -- for idempotency
        if(register_operands[place.type]) then
            return place
        end


        
        if(place.type == "pr") then
            place.type = "t" -- clobbers type; probably should copy place instead
            table.insert(tac[self.method.id], {type = "ld", source=place, dest=place})
            return place
        end

        local next_reg = operand.t()
        emit_move(place, next_reg)

        return next_reg
    end

    function get_symbol(id)
        local temp_scope = current_scope
        while not temp_scope[id] and temp_scope.level > 0 do
            temp_scope = temp_scope.parent
        end

        return temp_scope[id], temp_scope.level
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
                for i = 1, #element.value do 
                    initialize_word(string.format("'%s'",string.sub(n.value.value.value, i, i)), start)
                    start.value = start.value + 1
                end   
            else           
                emit_assignment_expression(element)
                emit_move(element.place, start)
            end
        elseif(node_check(n, "INITIALIZER_LIST")) then
            for i, child in ipairs(n) do
                child.value_type = n.value_type.points_to -- this probably should be in the type checking module, but it's easier to just do it here
                emit_static_initializer(child, start)
                start.value = start.value + self:sizeof(child.value_type)
            end
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

    function emit_declaration(n)
        assert(n.value_type ~= nil, "Value type is nil")
        handle_name_definition_conflict(n.id)
        if(n.value_type.kind ~= Type.KINDS["FUNCTION"]) then
            current_scope[n.id.id] = {type = n.value_type, place=static_allocate_place(self:sizeof(n.initializer and n.initializer.value_type or n.value_type))}
            if(n.initializer) then
                emit_static_initializer(n.initializer, current_scope[n.id.id].place)
            end

        else
            -- function definition
            assert(self.method.id == "!global", "Nested function definitions are not supported")
            current_scope[n.id.id] = {type = n.value_type, id = n.id.id, place=operand.i(n.id.id), parameters = n.parameter_list, local_size = 0, code={}}
            self.method = current_scope[n.id.id]
            tac[self.method.id] = {}

            new_scope(self.method.id .. "_scope")

            
            for i, p in ipairs(n.parameter_list or {}) do
                current_scope[p.id.id] = {type = "p", place=operand.p(i-1)}
            end
            if(n.block) then
                emit_block(n.block)
            else
                error("Function prototypes not supported yet")
            end
            exit_scope()
            self.method = global_method

        end
    end

    function new_scope(id)
        local new_scope = {level = current_scope.level + 1, parent = current_scope}
        current_scope[id] = new_scope
        current_scope = new_scope
    end

    function exit_scope()
        current_scope = current_scope.level == 0 and current_scope or current_scope.parent
    end

    -- FIX
    function emit_list_initializer(n, start)
        assert(start.type == "l" or start.type == "g", "List initializer base is neither a local or a global variable")

        local inner_type_size = self:sizeof(type.value.points_to)
        local index = start.value
        for i = 1, #n do
            emit_assignment_expression(n[i])
            emit_move(n[i].place, {type=start.type, value=index})
            index = index + 1
        end

    end

    function emit_expression(n)
        for i = 1, #n do
            emit_assignment_expression(n[i])
        end
        
        n.place = n[#n].place
    end

    function emit_assignment_expression(n)
        if (n.lhs) then 
            emit_ternary_expression(n.lhs)
            -- n.lhs.place.type = "g"
            emit_assignment_expression(n.rhs)
            n.place = emit_move(n.rhs.place, n.lhs.place) -- emit_move will return the source for optimization reasons

        else
            emit_ternary_expression(n)
            -- n.place is assumed to have been updated in either emit_ternary_expression or somewhere in the chain of function calls
        end

    end

    function emit_ternary_expression(n)
        emit_sum_expression(n)
    end

    function emit_move(source, dest)
        assert(dest.type ~= "i", "destination type cannot be an immediate value")

        source = source.type ~= "pr" and source or load_operand_into_register(source)

        local is_source_mem = memory_operands[source.type]
        local is_dest_mem = memory_operands[dest.type]

        if(source.type == "i" and is_dest_mem) then
            local next_reg = operand.t()
            table.insert(tac[self.method.id], {type="mov", source=source, dest=next_reg})
            source = next_reg -- source is still guaranteed to not be a memory based operand
        end


        if(not is_source_mem and not is_dest_mem) then
            table.insert(tac[self.method.id], {type="mov", source=source, dest=dest})
        elseif(not is_source_mem and is_dest_mem) then
            table.insert(tac[self.method.id], {type="st", source=source, dest=dest})
        elseif(is_source_mem and not is_dest_mem) then
            table.insert(tac[self.method.id], {type="ld", source=source, dest=dest})
        else
            -- source and dest are both memory based operands
            local t = operand.t()
            table.insert(tac[self.method.id], {type="ld", source=source, dest=t})
            table.insert(tac[self.method.id], {type="st", source=t, dest=dest})
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
            emit_declaration(n.child)
        elseif(n.child.type == NODE_TYPES["RETURN"]) then
            emit_return(n.child)
        else
            emit_expression(n.child)
        end
    end

    function emit_return(n)
        emit_expression(n.value)
        -- EDIT THIS
        if(memory_operands[n.value.place.type] or n.value.place.type == "i") then
            n.value.place = load_operand_into_register(n.value.place)
        end

        table.insert(tac[self.method.id], {type="mov", source=n.value.place, dest=self.RETURN_REG})
        table.insert(tac[self.method.id], {type="jmp", target=".exit_"..self.method.id})

    end

    function emit_local_declaration(n)
        handle_name_definition_conflict(n.id.id)
        n.place = operand.l(self:sizeof(n.type_specifier), self.method)
        current_scope[n.id.id] = {type = n.type_specifier, place=n.place}
        emit_assignment_expression(n.value)
        emit_move(n.value.place, current_scope[n.id.id].place)

    end

    function handle_name_definition_conflict(id)
        -- generally a name can only be redefined or shadowed if it exists in a scope level less than the current scope level
        if(current_scope[id]) then
            error(string.format("Symbol '%s' has already been defined in scope level %d", id, current_scope.level))
        end
    end

    function emit_function_call(n)
        if(n.id == "print_num" or n.id == "printf") then
            emit_assignment_expression(n.args[1])
            if(memory_operands[n.args[1].place.type]) then
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
            a = n[i]
            emit_assignment_expression(a)
            if(not is_standard_function) then
                if(memory_operands[a.place.type] or a.place.type == "i") then
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
        if(#n > 1) then
            n.place = load_operand_into_register(n[1].place)
        else
            n.place = n[1].place
        end
        for i = 3, #n, 2 do
            
            emit_term(n[i])
            -- term
            if(memory_operands[n[i].place.type]) then
                n[i].place = load_operand_into_register(n[i].place)
            end
            
            if(n[i-1].type == TOKEN_TYPES['+']) then
                if(n.value_type.kind == Type.KINDS["POINTER"]) then
                    emit_abstract_add(n[i].place, n.place, self:sizeof(n.value_type.points_to))
                else
                    table.insert(tac[self.method.id], {type="add", source = n[i].place, dest=n.place})
                end
            else
                table.insert(tac[self.method.id], {type="sub", source = n[i].place, dest=n.place})
            end
        end
    end

    function emit_abstract_add(source, dest, size)
        -- source is either an imm or reg while dest is a reg
        if(size > 1) then
            table.insert(tac[self.method.id], {type="mull", source=operand.i(size), dest=source})
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
            -- factor
            if(memory_operands[n[i].place.type]) then
                n[i].place = load_operand_into_register(n[i].place)
            end

            if(n[i-1].type == TOKEN_TYPES['*']) then
                table.insert(tac[self.method.id], {type="mull", source = n[i].place, dest=n.place})
            else
                table.insert(tac[self.method.id], {type="div", source = n[i].place, dest=n.place})
            end
        end
    end

    function emit_cast_expression(n)

        if(node_check(n, "CAST_EXPRESSION")) then
            emit_unary_expression(n.unary_expression)
        else
            emit_unary_expression(n)
        end
    end

    function emit_unary_expression(n)
        if(node_check(n, "UNARY_EXPRESSION")) then
            if(n.operator == "++") then
                emit_unary_expression(n.child)
                local next_reg = load_operand_into_register(n.child.place)
                table.insert(tac[self.method.id], {type="add", source=operand.i(1), dest=next_reg})
                emit_move(next_reg, n.child.place)
                table.insert(tac[self.method.id], {type="sub", source=operand.i(1), dest=next_reg})
            elseif(n.operator == "--") then
                emit_unary_expression(n.child)
                local next_reg = load_operand_into_register(n.child.place)
                table.insert(tac[self.method.id], {type="sub", source=operand.i(1), dest=next_reg})
                emit_move(next_reg, n.child.place)
                table.insert(tac[self.method.id], {type="add", source=operand.i(1), dest=next_reg})
            elseif(n.operator == "SIZEOF") then
                emit_cast_expression(n.child)
                n.place = operand.i(self:sizeof(n.child.value_type))
                table.insert(tac[self.method.id], {type="mov"})
                error()
            elseif(n.operator == "&") then
                emit_cast_expression(n.child)
                if(n.child.place.type == "pr") then
                    n.place = n.child.place
                    n.place.type = "t" -- ok to clobber child's place
                else
                    n.place = operand.t()
                    table.insert(tac[self.method.id], {type="!get_address", target=n.child.place, dest=n.place})
                end
            elseif(n.operator == "*") then
                emit_cast_expression(n.child)
                n.place = emit_dereference(n.child.place)
            end
        else
            emit_postfix_expression(n)
        end
    end

    function emit_dereference(place)
        local pr = nil
        if(place.type == "g") then
            pr = operand.pr()
            table.insert(tac[self.method.id], {type="ld", source=place, dest=pr})
        elseif(place.type == "t") then
            -- treat as pr
            place.type = "pr"
            pr = place
        elseif(place.type == "pr") then
            pr = place
        else
            error()
        end
        return pr
    end

    function emit_postfix_expression(n)
        if(node_check(n, "POSTFIX_EXPRESSION")) then
            emit_primary_expression(n.primary_expression)
            n.place = n.primary_expression.place
            if(n.primary_expression.place.type ~= "pr" and n.place.type ~= "i") then
                n.place = load_operand_into_register(n.place)
            end
            for _, operation in ipairs(n) do
                if(operation.type == "[") then
                    emit_expression(operation.value)

                    if(not register_operands[operation.value.place.type]) then
                        operation.value.place = load_operand_into_register(operation.value.place) -- use r value
                    end
                    emit_abstract_add(operation.value.place, n.place, self:sizeof(n.value_type))
                    n.place = emit_dereference(n.place)
                elseif(operation.type == "(") then
                    emit_argument_list(operation.value, n.place.is_standard_function)

                    if(memory_operands[n.place.type]) then
                        n.place = load_operand_into_register(n.place)
                    end
                    table.insert(tac[self.method.id], {type="call", target=n.place}) -- fix this
                    if(not n.place.is_standard_function) then
                        table.insert(tac[self.method.id], {type="add", source=operand.i(#operation.value), dest=self.STACK_POINTER}) -- destroy stack frame
                    end
                    n.place = operand.t()
                    table.insert(tac[self.method.id], {type="mov", source=self.RETURN_REG, dest=n.place})
                end
            end
        else
            emit_primary_expression(n)
        end
    end

    

    function emit_primary_expression(n)
        
        if(node_check(n, "INT")) then
            n.place = operand.i(n.value)
        elseif(node_check(n, "IDENTIFIER")) then
            local symbol = get_symbol(n.value)
            if(symbol) then
                if(symbol.type.kind == Type.KINDS["ARRAY"]) then
                    n.place = operand.t()
                    table.insert(tac[self.method.id], {type="!get_address", target=symbol.place, dest=n.place})
                else
                    n.place = symbol.place
                end
            else
                error(string.format("Variable '%s' used before definition", n.value))
            end
        elseif(node_check(n, "EXPRESSION")) then
            emit_expression(n);
        end
    end

    emit_program(ast)

    -- for i, c in ipairs(code) do
    --     if(c.type == "call") then
    --         print(i .. " " .. c.type .. " target=" .. c.target .. "\n")
    --     else
    --         print(i .. ' ' .. c.type .. ' source=' .. c.source.type .. c.source.value .. '; dest=' .. c.dest.type .. c.dest.value)
    --     end
    -- end
    self.symbol_table = current_scope

    return self
end

return IRVisitor