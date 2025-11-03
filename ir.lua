local Node = require('node')
local Token = require('token')
local Operand = require('operand')

-- Intermediate representation code generation

local IRVisitor = { tac = {["!global"]={}},
                    symbol_table = {},
                    temp = 4,
                    global = -1,
                    types = {["int"]=1, ["char"]=1, ["void"]=1},
                    global_method = {id = "!global"}
                    }
IRVisitor.method = IRVisitor.global_method
local operand = {
    l=function(s) return Operand:new("l", IRVisitor:next_stack(s)) end, -- local variable
    p=function(v) return Operand:new("p", v) end,                   -- parameter
    g=function(s) return Operand:new("g", IRVisitor:next_global(s)) end, -- global variable
    i=function(v) return Operand:new("i", v) end,                      -- immediate
    t=function() return Operand:new("t", IRVisitor:next_temp()) end,    -- temporary    
    r=function(v) return Operand:new("r", v) end                        -- binded register
}
IRVisitor.RETURN_REG = operand.r("return_reg")
IRVisitor.STACK_POINTER = operand.r("stack_pointer")
IRVisitor.BASE_POINTER = operand.r("base_pointer")
IRVisitor.__index = IRVisitor

function IRVisitor:next_stack(size)
    result = method.local_size
    method.local_size = result + size
    return result
end

function IRVisitor:next_temp()
    self.temp = self.temp + 1
    return self.temp
end

function IRVisitor:next_global(size)
    self.global = self.global + size
    return self.global
end

function IRVisitor:sizeof(type)
    return self.types[type]
end

function IRVisitor:generate_ir_code(ast)
    NODE_TYPES = Node.NODE_TYPES
    TOKEN_TYPES = Token.TOKEN_TYPES
    PLACE_TYPES = Operand.PLACE_TYPES
    tac = self.tac
    symbol_table = self.symbol_table
    global_method = self.global_method
    method = self.method

    memory_operands = {["l"]=1,["p"]=2,["g"]=3}
    
    function emit_program(n)
        for _, child in ipairs(n) do
            emit_declaration(child)
        end
    end


    function load_operand_into_register(place)
        next_reg = operand.t()
        if(memory_operands[place.type]) then
            table.insert(tac[method.id], {type="ld", source=place, dest=next_reg})
        elseif(place.type == "i") then
            table.insert(tac[method.id], {type="mov", source=place, dest=next_reg})
        end

        return next_reg
    end

    function emit_declaration(n)
        if(not n.id.is_function) then
            emit_expression(n.value)
            -- find source from expression node
            -- an expression will always return a temporary value 
            n.place = operand.g(self:sizeof(n.type_specifier.value))
            if(n.place.type == "i" or n.place.type == "g") then
                -- copy immediate to register first
                n.value.place = load_operand_into_register(n.value.place)
            end
            table.insert(tac[method.id], {type="st", source=n.value.place, dest=n.place})

            -- should not be needed, but the place of this declaration is the last generated temp id
            -- update symbol table
            symbol_table[n.id.id] = {type = n.type_specifier, scope = current_scope, place=n.place}
        else
            -- function declaration
            symbol_table[n.id.id] = {type = n.type_specifier, id = n.id.id, parameters = n.parameter_list, local_size = 0, code={}}
            method = symbol_table[n.id.id]
            tac[method.id] = {}


            for i, p in ipairs(n.parameter_list) do
                symbol_table[p.id.id] = {type = "p", place=operand.p(i-1)}
            end
            emit_block(n.block)
            method = global_method
        end
    end

    function emit_block(n)
        for i, s in ipairs(n) do
            emit_statement(s)
        end
    end

    function emit_statement(n)
        if(n.child.type == NODE_TYPES["LOCAL_DECLARATION"]) then
            emit_local_declaration(n.child)
        elseif(n.child.type == NODE_TYPES["FUNCTION_CALL"]) then
            emit_function_call(n.child)
        elseif(n.child.type == NODE_TYPES["ASSIGNMENT"]) then
            emit_assignment(n.child)
        elseif(n.child.type == NODE_TYPES["RETURN"]) then
            emit_return(n.child)
        end
    end

    function emit_return(n)
        emit_expression(n.value)

        if(memory_operands[n.value.place.type] or n.value.place.type == "i") then
            n.value.place = load_operand_into_register(n.value.place)
        end

        table.insert(tac[method.id], {type="mov", source=n.value.place, dest=self.RETURN_REG})
        table.insert(tac[method.id], {type="jmp", target=".exit_"..method.id})

    end

    function emit_local_declaration(n)
        emit_expression(n.value)

        n.place = operand.l(self:sizeof(n.type_specifier.value))
        if((memory_operands[n.value.place.type] or n.value.place.type == "i")) then
            n.value.place = load_operand_into_register(n.value.place)
        end
        table.insert(tac[method.id], {type="st", source=n.value.place, dest=n.place})
        symbol_table[n.id.id] = {type = n.type_specifier, scope = current_scope, place=n.place}

    end

    function emit_assignment(n)
        emit_expression(n.value)
        if((n.value.place.type == "i" or memory_operands[n.value.place.type])) then
            n.value.place = load_operand_into_register(n.value.place)
        end
        table.insert(tac[method.id], {type="st", source=n.value.place, dest=symbol_table[n.id.id].place})
    end


    function emit_function_call(n)
        if(n.id == "print_num") then
            emit_expression(n.args[1])
            if(memory_operands[n.args[1].place.type]) then
                table.insert(tac[method.id], {type="ld", source=n.args[1].place, dest=operand.r("r1")})
            else
                table.insert(tac[method.id], {type="mov", source=n.args[1].place, dest=operand.r("r1")})
            end
            table.insert(tac[method.id], {type="call", target=n.id})
        else
            emit_argument_list(n.args)
            table.insert(tac[method.id], {type="call", target=n.id})
            table.insert(tac[method.id], {type="add", source=operand.i(#n.args), dest=self.STACK_POINTER}) -- destroy stack frame
        end
    end

    function emit_argument_list(n)
        for i=#n, 1, -1 do
            a = n[i]
            emit_expression(a)
            if(memory_operands[a.place.type] or a.place.type == "i") then
                a.place = load_operand_into_register(a.place)
            end
            table.insert(tac[method.id], {type="push", target=a.place})
        end
    end
        

    function emit_expression(n)
        emit_term(n[1])
        if((n[1].place.type == "i" or memory_operands[n[1].place.type]) and #n > 1) then
            n.place = load_operand_into_register(n[1].place)
        else
            n.place = n[1].place
        end
        for i = 2, #n do
            
            if (i % 2 == 1) then
                emit_term(n[i])
                -- term
                if((n[i].place.type == "i" or memory_operands[n[i].place.type]) and #n > 1) then
                    n[i].place = load_operand_into_register(n[i].place)
                end
                
                if(n[i-1].type == TOKEN_TYPES['+']) then
                    table.insert(tac[method.id], {type="add", source = n[i].place, dest=n.place})
                else
                    table.insert(tac[method.id], {type="sub", source = n[i].place, dest=n.place})
                end
            end
        end
    end

    function emit_term(n)
        emit_factor(n[1])
        if((n[1].place.type == "i" or memory_operands[n[1].place.type]) and #n > 1) then
            n.place = load_operand_into_register(n[1].place)
        else
            n.place = n[1].place
        end
        --print("term" .. n.place)
        for i = 2, #n do
            
            if (i % 2 == 1) then
                emit_factor(n[i])
                -- factor
                if((n[i].place.type == "i" or memory_operands[n[i].place.type]) and #n > 1) then
                    n[i].place = load_operand_into_register(n[i].place)
                end
                if(n[i-1].type == TOKEN_TYPES['*']) then
                    table.insert(tac[method.id], {type="mull", source = n[i].place, dest=n.place})
                else
                    table.insert(tac[method.id], {type="div", source = n[i].place, dest=n.place})
                end
            end
        end
    end

    function emit_factor(n)
        -- Check whether n.value is of type INT literal, a variable or an expression
        if(n.value.type == NODE_TYPES["Int"]) then
            n.place = operand.i(n.value.value)
        elseif(n.value.type == NODE_TYPES["Identifier"]) then
            n.place = symbol_table[n.value.id].place
        elseif(n.value.type == NODE_TYPES["FUNCTION_CALL"]) then
            emit_function_call(n.value)
            n.place = operand.t()
            table.insert(tac[method.id], {type="mov", source=self.RETURN_REG, dest=n.place})
        else
            -- expression
            emit_expression(n.value)

            n.place = n.value.place
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
    return self
end

return IRVisitor