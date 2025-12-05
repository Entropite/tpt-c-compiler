local Node = require('node')
local util = require('util')
local serpent = require('serpent')
local Type = require('type')
local Type_Checker = {}


function Type_Checker:type_check(ast)
    local base = Type.base
    local pointer = Type.pointer
    local array = Type.array
    local func = Type.func
    local to_string = Type.to_string
    local to_string_pretty = Type.to_string_pretty
    local same_type_chain = Type.same_type_chain
    local is_base_type = Type.is_base_type

    local NODE_TYPES = Node.NODE_TYPES
    local node_check = Node.node_check

    local symbol_table = {["print_num"]=func(base("INT"), {base("INT")})}
    setmetatable(symbol_table, {__index = function(t, k) error("Symbol " .. k .. " used before declaration") end})

    function check_program(n)
        for _, child in ipairs(n) do
            build_type(child)
        end

        return n
    end

    function fill_array_dimensions(target_type, initializer_type)
        while(target_type ~= nil and initializer_type ~= nil) do
            if(target_type.kind == Type.KINDS["ARRAY"] and initializer_type.kind == Type.KINDS["ARRAY"] and target_type.length == -1) then
                target_type.length = initializer_type.length
            end

            target_type = target_type.points_to
            initializer_type = initializer_type.points_to
        end
    end

    function build_type(n)
        local base_type = base(n.specifier.type_specifier.kind)
        
        n.value_type = build_declarator(n.declarator, base_type);


        if(n.initializer) then
            if(n.value_type.kind == Type.KINDS["ARRAY"] and n.initializer.type ~= Node.NODE_TYPES["INITIALIZER_LIST"]) then
                error("Arrays can only be declared with initializer lists")
            end
            check_initializer(n.initializer)
            print("declared type: " .. to_string_pretty(n.value_type))
            print("initializer type: " .. to_string_pretty(n.initializer.value_type))
            if(not can_coerce(n.initializer.value_type, n.value_type, true)) then
                error("The initializer type must match the declared type")
            end
            fill_array_dimensions(n.value_type, n.initializer.value_type)
            print("filled array dimensions: " .. to_string_pretty(n.value_type))
        end

        symbol_table[n.declarator.direct_declarator.id.id] = n.value_type

        if(n.block) then
            check_block(n.block)
        end

        return n.value_type
    end

    function check_block(n)
        for _, child in ipairs(n) do
            check_statement(child)
        end
    end

    function check_statement(n)
        if(node_check(n.child, "DECLARATION")) then
            build_type(n.child)
        elseif(node_check(n.child, "RETURN")) then
            check_return(n.child)
        elseif(node_check(n.child, "EXPRESSION")) then
            check_expression(n.child)
        end
    end

    function array_coerce(type1, type2)
        -- builds a new synthetic type that is a result of the coersion of the array elements
        local result = array(0, nil)
        local start = result
        while(type1 ~= nil and type2 ~= nil) do
            if(type1.kind == Type.KINDS["ARRAY"] and type2.kind == Type.KINDS["ARRAY"]) then
                result.points_to = array(math.max(type1.length, type2.length),nil)
                type1 = type1.points_to
                type2 = type2.points_to
            elseif(can_coerce(type2, type1)) then
                result.points_to = type1
                break
            elseif(can_coerce(type1, type2)) then
                result.points_to = type2
                break
            else
                print("array coerce failed: " .. to_string(type1) .. " to " .. to_string(type2))
                return nil
            end

            result = result.points_to
        end
        return start.points_to
    end

    function get_type_chain_length(type)
        local length = 0
        while(type ~= nil) do
            length = length + 1
            type = type.points_to
        end

        return length
    end


    function can_coerce(type, target, allow_greater_target_length)
        allow_greater_target_length = allow_greater_target_length or false
        -- array to pointer decay
        while(type ~= nil and target ~= nil) do
            -- can coerce when both types are base types or if the coerced type is void at any point in the type chain
            if(is_base_type(type) and is_base_type(target) or type.kind == Type.KINDS["VOID"]) then
                return true
            elseif(type.kind ~= target.kind and not (type.kind == Type.KINDS["ARRAY"] and target.kind == Type.KINDS["POINTER"])) then
                break
            elseif(type.length ~= nil and target.length ~= nil and (type.length > target.length or (target.length > type.length and not allow_greater_target_length))) then
                if(target.length ~= -1) then -- -1 means the target array has unknown dimensions that will later be filled
                    break
                end
            end
            type = type.points_to
            target = target.points_to
        end

        return false
    end
        

    function check_initializer(n)
        if(n.type == Node.NODE_TYPES["INITIALIZER_LIST"]) then
            for _, child in ipairs(n) do
                check_initializer(child)
            end

            -- ensure all elements are the same type; coerce if necessary
            local temp_type = #n > 0 and n[1].value_type or base("VOID")
            for i=2, #n do
                local child = n[i]
                temp_type = array_coerce(child.value_type, temp_type)
                if(not temp_type) then
                    error("Initializer list elements must be of the same type; cannot coerce " .. to_string(child.value_type) .. " to " .. to_string(temp_type))
                end
            end

            n.value_type = array(#n, temp_type)
        else
            n.value_type = check_assignment_expression(n.value)
        end

        return n.value_type
    end

    function check_expression(n)
        for _, child in ipairs(n) do
            check_assignment_expression(child)
        end

        n.value_type = n[#n].value_type
        return n.value_type
    end

    function check_assignment_expression(n)
        -- May not have a lhs or rhs
        if(node_check(n, "ASSIGNMENT")) then
            local lhs_type = check_ternary_expression(n.lhs)
            local rhs_type = check_assignment_expression(n.rhs)
            if(not same_type_chain(lhs_type, rhs_type, true)) then
                error("Assignment types do not match")
            end
            n.value_type = lhs_type
        else
            n.value_type = check_ternary_expression(n)
        end

        return n.value_type
    end

    function check_ternary_expression(n)
        if(node_check(n, "TERNARY")) then
            local condition_type = check_sum_expression(n.condition)
            local true_case_type = check_assignment_expression(n.true_case)
            local false_case_type = check_sum_expression(n.false_case)
            if(not same_type_chain(false_case_type, true_case_type, true)) then
                error("Ternary false and true case types do not match")
            end
            n.value_type = true_case_type
        else
            n.value_type = check_sum_expression(n)
        end

        return n.value_type
    end

    function check_sum_expression(n)
        
        if(node_check(n, "SUM_EXPRESSION")) then
            local pointer_type = nil
            for i=1, #n, 2 do
                local term = n[i]
                local term_type = check_term(term)
                if(term_type.kind == Type.KINDS["POINTER"]) then
                    pointer_type = term_type
                elseif(term_type.kind ~= Type.KINDS["INT"]) then
                    error("Sum expression term types must be ints or pointers")
                end
            end
            if(pointer_type == nil) then
                n.value_type = n[1].value_type
            else
                n.value_type = pointer_type
            end
        else
            n.value_type = check_term(n)
        end

        return n.value_type
    end

    function check_term(n)
        if(node_check(n, "MULTIPLICATIVE_EXPRESSION")) then
            for i=1, #n, 2 do
                local factor = n[i]
                local factor_type = check_cast_expression(factor)
                if(factor_type.kind == Type.KINDS["POINTER"]) then
                    if(#n > 1) then
                        error("Cannot multiply or divide a pointer")
                    end
                elseif(factor_type.kind ~= Type.KINDS["INT"]) then
                    error("Can only multiply or divide an int by an int")
                end
            end

            n.value_type = n[1].value_type
        else
            n.value_type = check_cast_expression(n)
        end
        
        return n.value_type
    end

    function check_cast_expression(n)
        if(node_check(n, "CAST_EXPRESSION")) then
            n.value_type = check_type_specifier(n.type_specifier)
        else
            n.value_type = check_unary_expression(n)
        end
        return n.value_type
    end

    function check_type_specifier(n)
        n.value_type = base(string.upper(n.kind))
        return n.value_type
    end

    function check_unary_expression(n)
        if(node_check(n, "UNARY_EXPRESSION")) then
            check_unary_expression(n.child)
            if(n.operator == "++" or n.operator == "--") then
                if(n.child.value_type.kind == Type.KINDS["INT"] or n.child.value_type.kind == Type.KINDS["POINTER"]) then
                    n.value_type = n.child.value_type
                else
                    error("pre-increment/decrement is only valid for ints or pointers")
                end
            elseif(n.operator == "SIZEOF") then
                n.value_type = base("INT")
            elseif(n.operator == "&") then
                n.value_type = pointer(n.child.value_type)
            elseif(n.operator == "*") then
                n.value_type = n.child.value_type.points_to
            elseif(n.operator == "!") then
                n.value_type = base("INT")
            elseif(n.operator == "~") then
                n.value_type = base("INT")
            elseif(n.operator == "-") then
                if(n.child.value_type.kind == Type.KINDS["INT"] or n.child.value_type.kind == Type.KINDS["POINTER"]) then
                    n.value_type = n.child.value_type
                else
                    error("unary minus is only valid for ints or pointers")
                end
            elseif(n.operator == "+") then
                if(n.child.value_type.kind == Type.KINDS["INT"] or n.child.value_type.kind == Type.KINDS["POINTER"]) then
                    n.value_type = n.child.value_type
                else
                    error("unary plus is only valid for ints or pointers")
                end
            else
                error()
            end
        else
            check_postfix_expression(n)
        end

        return n.value_type
    end

    function check_postfix_expression(n)
        if(node_check(n, "POSTFIX_EXPRESSION")) then
            local primary_expression_type = check_primary_expression(n.primary_expression)
            n.value_type = primary_expression_type;
            for _, operation in ipairs(n) do
                if(operation.type == "[") then
                    local index_type = check_expression(operation.value)
                    if(can_coerce(index_type, base("INT"))) then
                        n.value_type = primary_expression_type.points_to
                    else
                        error("Array index must be an int")
                    end
                elseif(operation.type == "(") then
                    n.value_type = n.value_type.kind == Type.KINDS["POINTER"] and n.value_type.points_to or n.value_type
                    if(n.value_type.kind == Type.KINDS["FUNCTION"]) then
                        check_argument_list(operation.value, n.value_type.parameter_types)
                        n.value_type = n.value_type.return_type
                    else
                        error("Function call can only be performed on a function")
                    end
                end
                -- TODO: add member access type checking here
            end
        else
            check_primary_expression(n)
        end

        return n.value_type
    end

    function check_argument_list(arguments, parameter_types)
        if(#arguments ~= #parameter_types) then
            error("Argument list length does not match the parameter list length")
        end

        for i, argument in ipairs(arguments) do
            local argument_type = check_assignment_expression(argument)
            if(not can_coerce(argument_type, parameter_types[i])) then
                error("Argument type does not match parameter type")
            end
        end
    end

    function check_primary_expression(n)
        if(node_check(n, "INT")) then
            n.value_type = base("INT")
        elseif(node_check(n, "IDENTIFIER")) then
            n.value_type = symbol_table[n.value]
            if(n.value_type.kind == Type.KINDS["ARRAY"]) then
                n.value_type = pointer(n.value_type.points_to)
            elseif(n.value_type.kind == Type.KINDS["FUNCTION"]) then
                n.value_type = pointer(n.value_type)
            end
        elseif(node_check(n, "STRING_LITERAL")) then
            error()
            -- TODO:Finish the other primary expression types
        elseif(node_check(n, "EXPRESSION")) then
            n.value_type = check_expression(n)
        else
            print(n.type)
            error()
        end
        return n.value_type
    end



    function check_factor(n)
        if(n.value.type == Node.NODE_TYPES["INT"]) then
            n.value_type = base("INT")
        elseif(n.value.type == Node.NODE_TYPES["IDENTIFIER"]) then
            n.value_type = symbol_table[n.value.id]
            if(n.value_type.kind == Type.KINDS["ARRAY"]) then
                n.value_type = pointer(n.value_type.points_to)
            end
        elseif(n.value.type == Node.NODE_TYPES["FUNCTION_CALL"]) then
            n.value_type = symbol_table[n.value.id].type.return_type
        elseif(n.value.type == Node.NODE_TYPES["ADDRESS_OF"]) then
            local original_type = symbol_table[n.value.id]
            if(original_type.kind == Type.KINDS["ARRAY"]) then
                n.value_type = pointer(original_type.points_to)
            else
                n.value_type = pointer(original_type)
            end
        elseif(n.value.type == Node.NODE_TYPES["DEREFERENCE"]) then
            n.value_type = symbol_table[n.value.id].points_to
        elseif(n.value.type == Node.NODE_TYPES["STRING_LITERAL"]) then
            n.value_type = array(#n.value.value,base("CHAR"))
        elseif(n.value.type == Node.NODE_TYPES["CHARACTER"]) then
            n.value_type = base("CHAR")
        end

        return n.value_type
    end

    function build_declarator(n, base_type)
        local type = base_type
        for i=1, n.pointer_level do
            type = pointer(type)
        end

        type = build_direct_declarator(n.direct_declarator, type)

        return type
    end

    function build_direct_declarator(n, type)
        for i=#n.dimensions, 1, -1 do
            type = array(n.dimensions[i], type)
        end
        if(n.parameter_list) then -- FIX THIS
            type = func(type, build_parameter_list(n.parameter_list))
        end

        print(to_string_pretty(type))
        if(n.declarator) then
            type = build_declarator(n.declarator, type)
        end

        return type
    end

    function build_parameter_list(n)
        local parameter_types = {}
        for _, child in ipairs(n) do
            table.insert(parameter_types, build_declarator(child.declarator, base(child.type_specifier.kind)))
        end

        return parameter_types
    end

    return check_program(ast)
end


return Type_Checker