local Token = require('token')
local Node = require('node')

local Parser = {}

function Parser.parse(toks)
    local TOKEN_TYPES = Token.TOKEN_TYPES
    local INVERTED_TOKENS = Token.INVERTED_TOKENS
    local NODE_TYPES = Node.NODE_TYPES

    local unary_operators = {"&", "*", "+", "-", "~", "!"}
    local type_specifiers = {"void", "char", "int", "struct", "union"}

    function new(type)
        return Node:new(NODE_TYPES[type])
    end
    --local symbol_table = {}
    local ast = {}
    
    local i = 0
    function next_token()
        i = i + 1
        return toks[i]
    end

    function peek_token()
        -- The very last token is guaranteed to be EOF
        return toks[i + 1]
    end

    function expect(type)
        local t = next_token()
        if not t or t.type ~= TOKEN_TYPES[type] then
            error("Expected '" .. type .. "', Received '" .. (t and t.value or "EOF") .. "'")
        end
    end

    function multi_expect(array)
        for i, t in ipairs(array) do
            if(accept(t)) then
                return
            end
        end

        error("Syntax error (multi_expect)")
    end


    function accept(type)
        local t = peek_token()
        if t and t.type == TOKEN_TYPES[type] then
            next_token()
            return true
        else
            return false
        end
    end

    function check(type)
        local t = peek_token()
        return t and t.type == TOKEN_TYPES[type]
    end

    function multi_check(array)
        for i, t in ipairs(array) do
            if(check(t)) then
                return true
            end
        end

        return false
    end

    function parse_program()
        local program_node = Node:new(NODE_TYPES["Program"])
        
        while peek_token().type ~= TOKEN_TYPES["EOF"] do

            table.insert(program_node, parse_declaration())
            accept(";") -- temp solution
        end

        return program_node
    end

    function parse_declaration()
        local declaration_node = new("DECLARATION")
        declaration_node.specifier = parse_declaration_specifier()
        declaration_node.declarator = parse_declarator()
        declaration_node.id = declaration_node.declarator.direct_declarator.id

        declaration_node.is_function = declaration_node.declarator.direct_declarator.parameter_list ~= nil
        if(check("{")) then
            declaration_node.block = parse_block()
        else
            if(accept("=")) then
                declaration_node.initializer = parse_initializer()
            end
        end

        return declaration_node
    end

    function parse_type_name()
        local type_name_node = new("TYPE_NAME")
        type_name_node.type_specifier = parse_type_specifier()
        type_name_node.declarator = parse_abstract_declarator()
        return type_name_node
    end

    function parse_abstract_declarator()
        local abstract_declarator_node = new("ABSTRACT_DECLARATOR")
        abstract_declarator_node.pointer_level = 0

        while(accept("*")) do
            abstract_declarator_node.pointer_level = abstract_declarator_node.pointer_level + 1
        end
        if(multi_check({"[", "("})) then
            abstract_declarator_node.direct_abstract_declarator = parse_direct_abstract_declarator()
        else
            error("Invalid type name")
        end
        return abstract_declarator_node
    end

    function parse_direct_abstract_declarator()
        local direct_abstract_declarator_node = new("DIRECT_ABSTRACT_DECLARATOR")
        if(accept("(")) then
            direct_abstract_declarator_node.declarator = parse_abstract_declarator()
            expect(")")
        end
        while(multi_check({"[", "("})) do
            if(accept("[")) then
                table.insert(direct_abstract_declarator_node, parse_expression())
                expect("]")
            elseif(accept("(")) then
                direct_abstract_declarator_node.parameter_list = parse_parameter_list()
                expect(")")
            end
        end
        return direct_abstract_declarator_node
    end

    function parse_parameter_list()
        local parameter_list_node = Node:new(NODE_TYPES["PARAMETER_LIST"])
        if(check(")")) then
            return parameter_list_node
        end
        table.insert(parameter_list_node, parse_parameter_declaration())
        while(accept(",")) do
            table.insert(parameter_list_node, parse_parameter_declaration())
        end

        return parameter_list_node
    end

    function parse_parameter_declaration()
        local parameter_declaration_node = new("PARAMETER_DECLARATION")
        parameter_declaration_node.type_specifier = parse_type_specifier()
        parameter_declaration_node.declarator = parse_declarator()
        return parameter_declaration_node
    end


    function parse_initializer()
        local initializer_node = nil
        if(accept("{")) then
            initializer_node = parse_initializer_list()
            accept(",")
            expect("}")
        elseif(not check("}")) then
            initializer_node = new("INITIALIZER")
            initializer_node.value = parse_assignment_expression()
        end

        return initializer_node
    end

    function parse_initializer_list()
        local initializer_list_node = new("INITIALIZER_LIST")
        table.insert(initializer_list_node, parse_initializer())

        while(accept(",")) do
            table.insert(initializer_list_node, parse_initializer())
        end

        return initializer_list_node
    end

    function parse_expression()
        local expression = new("EXPRESSION")
        table.insert(expression, parse_assignment_expression())

        while accept(",") do
            table.insert(expression, parse_assignment_expression())
        end

        return expression
    end

    function parse_assignment_expression()
        local lhs = parse_ternary_expression()

        if accept("=") then
            local rhs = parse_assignment_expression()
            local assignment_expression_node = new("ASSIGNMENT")
            assignment_expression_node.lhs = lhs
            assignment_expression_node.rhs = rhs
            return assignment_expression_node
        end
        
        return lhs
    end

    function parse_ternary_expression()
        local condition = parse_sum_expression()

        if accept("?") then
            local ternary_expression_node = new("TERNARY")
            ternary_expression_node.condition = condition
            ternary_expression_node.true_case = parse_assignment_expression()
            expect(":")
            ternary_expression_node.false_case = parse_sum_expression()

            return ternary_expression_node
        end

        return condition
    end


    function parse_parameter()
        local parameter_node = Node:new(NODE_TYPES["PARAMETER"])
        parameter_node.type_specifier = parse_type_specifier()
        parameter_node.id = parse_identifier()

        return parameter_node
    end

    function parse_block()
        local block_node = Node:new(NODE_TYPES["Block"])

        if accept("{") then
            while not check("}") do
                table.insert(block_node, parse_statement())
                expect(";")
            end
            expect("}")
        else
            error("Expected '{' to start block")
        end

        return block_node
    end

    function parse_statement()
        local statement_node = Node:new(NODE_TYPES["Statement"])
        local token = peek_token()
        -- Declaration
        if token.type == TOKEN_TYPES["TYPE_SPECIFIER"] then
            statement_node.child = parse_declaration()
        elseif token.type == TOKEN_TYPES["IF"] then
            statement_node.child = parse_if()
        elseif token.type == TOKEN_TYPES["FOR"] then
            statement_node.child = parse_for()
        elseif token.type == TOKEN_TYPES["WHILE"] then
            statement_node.child = parse_while()
        elseif token.type == TOKEN_TYPES["RETURN"] then
            statement_node.child = parse_return()
        else
            statement_node.child = parse_expression()
        end

        return statement_node
    end

    function parse_assignment()
        local assignment_node = Node:new(NODE_TYPES["Assignment"])
        if check("*") then
            assignment_node.indirection_level = 0
            while accept("*") do
                assignment_node.indirection_level = assignment_node.indirection_level + 1
            end
        end


        assignment_node.id = parse_identifier()

        if accept("[") then
            assignment_node.index = parse_expression()
            expect("]")
        end


        expect("=")
        assignment_node.value = parse_expression()


        return assignment_node;
    end

    function parse_return()
        local return_node = Node:new(NODE_TYPES["RETURN"])
        next_token()
        return_node.value = parse_expression()

        return return_node
    end


    function parse_local_declaration()
        local declaration_node = Node:new(NODE_TYPES["Local_Declaration"])

        declaration_node.type_specifier = parse_type_specifier()

        declaration_node.id = parse_identifier()

        if next_token().type == TOKEN_TYPES["="] then
            declaration_node.value = parse_assignment_expression()
        end

        return declaration_node
    end

    function parse_declaration_specifier()
        local declaration_specifier_node = new("DECLARATION_SPECIFIER")

        if(check("STORAGE_CLASS")) then
            declaration_specifier_node.storage_class = parse_storage_class_specifier()
        end

        if(check("TYPE_SPECIFIER")) then
            declaration_specifier_node.type_specifier = parse_type_specifier()
        else
            error(string.format("Invalid declaration specifier: '%s'", peek_token().value))
        end

        return declaration_specifier_node
    end

    function parse_declarator()
        local declarator_node = new("DECLARATOR")
        declarator_node.pointer_level = 0
        while(accept("*")) do
            declarator_node.pointer_level = declarator_node.pointer_level + 1
        end

        declarator_node.direct_declarator = parse_direct_declarator()

        return declarator_node
    end

    function parse_direct_declarator()
        local direct_declarator_node = new("DIRECT_DECLARATOR")
        if(check("ID")) then
            direct_declarator_node.id = parse_identifier()
        elseif(accept("(")) then
            direct_declarator_node.declarator = parse_declarator()
            direct_declarator_node.id = direct_declarator_node.declarator.direct_declarator.id
            expect(")")
        else
            error(string.format("Unexpected token: '%s'", peek_token()))
        end

        direct_declarator_node.dimensions = {}
        print("HELO")
        while(multi_check({"[", "("})) do
            if(accept("[")) then
                if(check("INT")) then
                    table.insert(direct_declarator_node.dimensions, next_token().value)
                else
                    table.insert(direct_declarator_node.dimensions, -1)
                end
                expect("]")
            elseif(accept("(")) then
                direct_declarator_node.parameter_list = parse_parameter_list()
                expect(")")
            end

            
        end

        return direct_declarator_node
    end

    function parse_type_specifier()
        local type_specifier_node = new("TYPE_SPECIFIER")

        if(check("TYPE_SPECIFIER")) then
            if(peek_token().value == "struct" or peek_token().value == "union") then
                type_specifier_node.kind = parse_struct_or_union_specifier()
            else
                type_specifier_node.kind = next_token().value
            end
        else
            error(string.format("Invalid type specifier: '%s'", peek_token()))
        end

        return type_specifier_node
    end

    function parse_struct_or_union_specifier()
        local struct_or_union_specifier_node = new("STRUCT_OR_UNION_SPECIFIER_NODE")

        multi_expect({"struct", "union"})
        if(check("ID")) then
            struct_or_union_specifier_node.id = parse_identifier()
        end

        if(accept("{")) then
            struct_or_union_specifier_node.declaration = parse_struct_declaration()
            expect("}")
        end

        return struct_or_union_specifier_node
    end

    function parse_struct_declaration()
        local struct_declaration_node = new("STRUCT_DECLARATION")
        if(multi_check({"void", "char", "int", "struct", "union"})) then
            struct_declaration_node.type_specifier = parse_type_specifier()
        else
            error(string.format("Invalid struct declaration type: '%s'", peek_token()))
        end

        struct_declaration_node.struct_declarator_list = parse_struct_declarator_list()
        
        error()
    end

    function parse_storage_class_specifier()
        local storage_class_specifier_node = new("STORAGE_CLASS_SPECIFIER")
        if(multi_check({"auto", "register", "static", "extern", "typedef"})) then
            storage_class_specifier_node.kind = next_token()
        else
            error(string.format("Invalid storage class: '%s'", peek_token().value))
        end

        return storage_class_specifier_node
    end

    -- function parse_type_specifier()
    --     local type_specifier_node = Node:new(NODE_TYPES["Type_Specifier"])

    --     local token = next_token()

    --     if token.value == "int" or token.value == "char" or token.value == "void" then
    --         type_specifier_node.kind = token.value
    --     else
    --         error("Unexpected type specifier: " .. token.value)
    --     end
    --     type_specifier_node.indirection_level = 0;

    --     while accept("*") do
    --         type_specifier_node.indirection_level = type_specifier_node.indirection_level + 1
    --     end

    --     return type_specifier_node
    --  end

    function parse_identifier()
        local identifier_node = Node:new(NODE_TYPES["Identifier"])

        local token = next_token()

        if token.type == TOKEN_TYPES["ID"] then
            identifier_node.id = token.value
        else
            error("Unexpected identifier: " .. token.value)
        end

        return identifier_node
    end

    function parse_sum_expression()

        local term = parse_term()
        if(check("+") or check("-")) then
            local sum_expression_node = Node:new(NODE_TYPES["SUM_EXPRESSION"])
            table.insert(sum_expression_node, term)
            while check("+") or check("-") do
                table.insert(sum_expression_node, next_token())
                table.insert(sum_expression_node, parse_term())
            end

            return sum_expression_node

        end

        return term
    end

    function parse_term()
        local factor = parse_cast_expression()
        if(check("*") or check("/")) then
            local multiplicative_expression_node = Node:new(NODE_TYPES["MULTIPLICATIVE_EXPRESSION"])
            table.insert(multiplicative_expression_node, factor)

            while check("*") or check("/") do
                
                table.insert(multiplicative_expression_node, next_token())
                table.insert(multiplicative_expression_node, parse_cast_expression())
            end

            return multiplicative_expression_node

        end

        return factor
    end

    function parse_cast_expression()
        if(check("(") and multi_check({"TYPE_SPECIFIER", "struct", "union"})) then
            local cast_expression_node = new("CAST_EXPRESSION")
            expect("(")
            cast_expression_node.type_specifier = parse_type_specifier()
            expect(")")
            cast_expression_node.cast_expression = parse_cast_expression()
            return cast_expression_node
        else
            return parse_unary_expression()
        end
    end

    function parse_unary_expression()
        local unary_expression_node = new("UNARY_EXPRESSION")
        if(multi_check({"++", "--"})) then
            unary_expression_node.operator = next_token().value
            unary_expression_node.child = parse_unary_expression()
        elseif(accept("SIZEOF")) then
            unary_expression_node.child = parse_type_specifier()
            unary_expression_node.operator = "SIZEOF"
            error("Change this to parse_type_name()")
        elseif(multi_check(unary_operators)) then
            unary_expression_node.operator = next_token().value
            unary_expression_node.child = parse_cast_expression()
        else
            return parse_postfix_expression()
        end
        return unary_expression_node
    end

    function parse_postfix_expression()
        local postfix_expression_node = new("POSTFIX_EXPRESSION")
        local primary_expression_node = parse_primary_expression()
        while(multi_check({"[", "(", ".", "->"})) do
            local operation = nil
            if(accept("[")) then
                operation = {type="[", value=parse_expression()}
                expect("]")
            elseif(accept("(")) then
                operation = {type="(", value=parse_argument_list()}
                expect(")")
            elseif(accept(".")) then
                operation = {type=".", value=parse_identifier()}
            elseif(accept("->")) then
                operation = {type="->", value=parse_identifier()}
            end
            table.insert(postfix_expression_node, operation)
        end
        if(accept("++")) then
            table.insert(postfix_expression_node, {type="++"})
        elseif(accept("--")) then
            table.insert(postfix_expression_node, {type="--"})
        end

        if(#postfix_expression_node > 0) then
            postfix_expression_node.primary_expression = primary_expression_node
            return postfix_expression_node
        else
            return primary_expression_node
        end
    end

    function parse_primary_expression()
        local node = nil
        if(check("INT")) then
            node = new("INT")
            node.value = next_token().value
        elseif(check("ID")) then
            node = new("IDENTIFIER")
            node.value = next_token().value
        elseif(check("STRING_LITERAL")) then
            node = new("STRING_LITERAL")
            node.value = string.sub(next_token().value, 2, -2)
        elseif(check("CHARACTER")) then
            node = new("CHARACTER")
            node.value = next_token().value
        elseif(accept("(")) then
            node = parse_expression()
            expect(")")
        else
            error("Unexpected token: " .. peek_token().value)
        end

        return node
    end


    function parse_factor()
        local factor_node = new("FACTOR")

        local token = peek_token()
        if token.type == TOKEN_TYPES["INT"] then
            next_token()
            local int_node = Node:new(NODE_TYPES["Int"])
            int_node.value = token.value

            factor_node.value = int_node
        elseif token.type == TOKEN_TYPES["ID"] then
            if(toks[i + 2].type == TOKEN_TYPES["("]) then
                factor_node.value = parse_function_call()
            else
                next_token()
                local identifier_node = Node:new(NODE_TYPES["Identifier"])
                identifier_node.id = token.value

                factor_node.value = identifier_node
            end
        elseif token.type == TOKEN_TYPES["("] then
            next_token()
            factor_node.value = parse_expression()

            expect(")")
        elseif check("&") then
            factor_node.value = parse_address_of()
        elseif check("*") then
            factor_node.value = parse_dereference()
        elseif check("STRING_LITERAL") then
            local string_literal_node = new("STRING_LITERAL")
            string_literal_node.value = string.sub(next_token().value, 2, -2)
            factor_node.value = string_literal_node
        elseif check("CHARACTER") then
            local character_node = new("CHARACTER")
            character_node.value = next_token().value
            factor_node.value = character_node
        else
            error("Unexpected token: " .. token.value)
        end

        return factor_node
    end

    function parse_dereference()
        local dereference_node = new("DEREFERENCE")
        expect("*")
        dereference_node.value = parse_sum_expression()

        return dereference_node
    end

    function parse_address_of()
        local address_of_node = new("ADDRESS_OF")
        expect("&")
        
        if check("ID") then
            address_of_node.id = next_token().value
        else
            error("Can only perform an address of operation on a variable")
        end

        return address_of_node
    end




    function parse_function_call()
        local function_call_node = Node:new(NODE_TYPES["FUNCTION_CALL"])
        function_call_node.id = next_token().value
        next_token()
        function_call_node.args = parse_argument_list()
        next_token()

        return function_call_node
    end

    function parse_argument_list()
        local argument_list_node = Node:new(NODE_TYPES["ARGUMENT_LIST"])
        if peek_token().type == TOKEN_TYPES[")"] then
            return argument_list_node
        end

        table.insert(argument_list_node, parse_assignment_expression())

        while peek_token().type == TOKEN_TYPES[","] do
            next_token()
            table.insert(argument_list_node, parse_assignment_expression())
        end

        return argument_list_node

    end

    function parse_if()
        local if_node = Node:new(NODE_TYPES["If"])
        next_token()

        if next_token().type ~= TOKEN_TYPES["("] then
            error("Expected '(' after 'if'")
        end

        if_node.condition = parse_expression()
        if next_token().type ~= TOKEN_TYPES[")"] then
            error("Expected ')' after condition")
        end

        if_node.block = parse_block()

        return if_node
    end

    function parse_for()
        local for_node = Node:new(NODE_TYPES["For"])

        next_token()
        if next_token().type ~= TOKEN_TYPES["("] then
            error("Expected '(' after 'for'")
        end

        for_node.initialization = parse_expression()

        if next_token().type ~= TOKEN_TYPES[";"] then
            error("Expected ';' after initialization")
        end

        for_node.condition = parse_expression()

        if next_token().type ~= TOKEN_TYPES[";"] then
            error("Expected ';' after condition")
        end

        for_node.update = parse_expression()

        if next_token().type ~= TOKEN_TYPES[")"] then
            error("Expected ')' after update")
        end

        for_node.block = parse_block()

        return for_node
    end

    return parse_program()
end



return Parser