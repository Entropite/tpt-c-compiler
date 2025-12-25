local Token = require('token')
local Node = require('node')
local Diagnostics = require("diagnostics")
local Message = require("message")

local Parser = {}

function Parser.parse(toks, symbol_table)
    local TOKEN_TYPES = Token.TOKEN_TYPES
    local INVERTED_TOKENS = Token.INVERTED_TOKENS
    local NODE_TYPES = Node.NODE_TYPES
    local node_check = Node.node_check

    local unary_operators = {"&", "*", "+", "-", "~", "!"}

    function new(type)
        if(type == nil or NODE_TYPES[type] == nil) then
            error("Invalid node type: " .. type)
        end
        return Node:new(NODE_TYPES[type], peek_token().pos)
    end

    function update_if_type_name(token)
        if(token.type == TOKEN_TYPES["ID"]) then
            local potential_type_name = symbol_table.get_symbol(token.value, symbol_table.ordinary)
            if(potential_type_name and potential_type_name.is_type_name) then
                token.type = TOKEN_TYPES["TYPE_SPECIFIER"]
            end
        end
        return token
    end
    
    local i = 0
    function next_token()
        i = i + 1
        return update_if_type_name(toks[i])
    end

    function peek_token()
        return update_if_type_name(toks[i + 1])
    end

    function expect(type)
        local t = next_token()
        if not t or t.type ~= TOKEN_TYPES[type] then
            Diagnostics.submit(Message.error(string.format("Expected '%s', Received '%s'", type, peek_token().value), peek_token().pos))
        end
    end

    function multi_expect(array)
        for i, t in ipairs(array) do
            if(accept(t)) then
                return true
            end
        end

        return false
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

    function check(type, lookahead)
        lookahead = lookahead or 0
        i = i + lookahead
        local t = peek_token()
        i = i - lookahead
        return t and t.type == TOKEN_TYPES[type]
    end

    function multi_check(array, lookahead)
        lookahead = lookahead or 0
        local found = false
        local saved_i = i
        i = i + lookahead
        for i, t in ipairs(array) do
            if(check(t)) then
                found = true
                break
            end
        end
        i = saved_i

        return found
    end

    function parse_program()
        if(#toks <= 0) then
            error("Empty file")
        end
        local program_node = new("PROGRAM")
    
        while peek_token().type ~= TOKEN_TYPES["EOF"] do

            table.insert(program_node, parse_declaration())
            if(not (program_node[#program_node].is_function and program_node[#program_node].block)) then
                expect(";")
            end
        end

        return program_node
    end

    function parse_declaration()
        local declaration_node = new("DECLARATION")
        declaration_node.specifier = parse_declaration_specifier()
        if(not check(";")) then
            declaration_node.declarator = parse_declarator()
            declaration_node.id = declaration_node.declarator.direct_declarator.id

            declaration_node.is_function = declaration_node.declarator.direct_declarator.parameter_list ~= nil
            if(declaration_node.is_function) then
                declaration_node.is_variadic = declaration_node.declarator.direct_declarator.parameter_list.is_variadic
            end
            if(check("{")) then
                declaration_node.block = parse_block()
            else
                if(accept("=")) then
                    declaration_node.initializer = parse_initializer()
                end
            end
        end

        if(declaration_node.specifier.storage_class.kind == "typedef") then
            symbol_table.add_symbol(declaration_node.id.id, {is_type_name = true}, symbol_table.ordinary)
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
                table.insert(direct_abstract_declarator_node, parse_integer_constant())
                expect("]")
            elseif(accept("(")) then
                direct_abstract_declarator_node.parameter_list = parse_parameter_list()
                expect(")")
            end
        end
        return direct_abstract_declarator_node
    end

    function parse_integer_constant()
        local int_node = new("INT")
        int_node.value = next_token().value
        return int_node
    end

    function parse_parameter_list()
        local parameter_list_node = new("PARAMETER_LIST")
        if(check(")")) then
            return parameter_list_node
        end
        table.insert(parameter_list_node, parse_parameter_declaration())
        if(not parameter_list_node[1].id and parameter_list_node[1].type_specifier.kind[1] == "void") then
            parameter_list_node[1] = nil
            return parameter_list_node
        end
        while(accept(",")) do
            if(accept("...")) then
                if(parameter_list_node.is_variadic) then
                    Diagnostics.submit(Message.error("Variadic parameters must be the last parameter", peek_token().pos))
                end
                parameter_list_node.is_variadic = true
            else
                table.insert(parameter_list_node, parse_parameter_declaration())
            end
        end

        return parameter_list_node
    end

    function parse_parameter_declaration()
        local parameter_declaration_node = new("PARAMETER_DECLARATION")
        parameter_declaration_node.type_specifier = parse_type_specifier()
        if(not multi_check({",", ")"})) then
            parameter_declaration_node.declarator = parse_declarator()
            parameter_declaration_node.id = parameter_declaration_node.declarator.direct_declarator.id
        end
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
        if multi_check({"=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>="}) then
            local pos = peek_token().pos
            local op = next_token().value
            local rhs = parse_assignment_expression()
            if(not (lhs ~= nil and rhs ~= nil)) then
                Diagnostics.submit(Message.error("Assignment expression must have a lhs and rhs", peek_token().pos))
            end
            local assignment_expression_node = new("ASSIGNMENT")
            assignment_expression_node.pos = pos
            assignment_expression_node.op = op
            assignment_expression_node.lhs = lhs
            assignment_expression_node.rhs = rhs
            return assignment_expression_node
        end
        
        return lhs
    end

    function parse_ternary_expression()
        local condition = parse_logical_or_expression()

        if accept("?") then
            local ternary_expression_node = new("TERNARY")
            ternary_expression_node.condition = condition
            ternary_expression_node.true_case = parse_assignment_expression()
            expect(":")
            ternary_expression_node.false_case = parse_logical_or_expression()

            return ternary_expression_node
        end

        return condition
    end

    function parse_logical_or_expression()
        
        local sub_expression = parse_logical_and_expression()
        if(check("||")) then
            local logical_or_expression_node = new("LOGICAL_OR_EXPRESSION")
            table.insert(logical_or_expression_node, sub_expression)
            while(accept("||")) do
                table.insert(logical_or_expression_node, parse_logical_and_expression())
            end

            return logical_or_expression_node
        end

        return sub_expression
    end

    function parse_logical_and_expression()
        
        local sub_expression = parse_inclusive_or_expression()
        if(check("&&")) then
            local logical_and_expression_node = new("LOGICAL_AND_EXPRESSION")
            table.insert(logical_and_expression_node, sub_expression)
            while(accept("&&")) do
                table.insert(logical_and_expression_node, parse_inclusive_or_expression())
            end

            return logical_and_expression_node
        end

        return sub_expression
    end

    function parse_inclusive_or_expression()
        local sub_expression = parse_inclusive_xor_expression()
        if(check("|")) then
            local inclusive_or_expression_node = new("INCLUSIVE_OR_EXPRESSION")
            table.insert(inclusive_or_expression_node, sub_expression)
            while(accept("|")) do
                table.insert(inclusive_or_expression_node, parse_inclusive_xor_expression())
            end

            return inclusive_or_expression_node
        end

        return sub_expression
    end

    function parse_inclusive_xor_expression()
        local sub_expression = parse_inclusive_and_expression()
        if(check("^")) then
            local inclusive_xor_expression_node = new("INCLUSIVE_XOR_EXPRESSION")
            table.insert(inclusive_xor_expression_node, sub_expression)
            while(accept("^")) do
                table.insert(inclusive_xor_expression_node, parse_inclusive_and_expression())
            end

            return inclusive_xor_expression_node
        end

        return sub_expression
    end

    function parse_inclusive_and_expression()
        local sub_expression = parse_equality_expression()
        if(check("&")) then
            local inclusive_and_expression_node = new("INCLUSIVE_AND_EXPRESSION")
            table.insert(inclusive_and_expression_node, sub_expression)
            while(accept("&")) do
                table.insert(inclusive_and_expression_node, parse_equality_expression())
            end

            return inclusive_and_expression_node
        end

        return sub_expression
    end

    function parse_equality_expression()
        local sub_expression = parse_relational_expression()
        if(check("==") or check("!=")) then
            local equality_expression_node = new("EQUALITY_EXPRESSION")
            table.insert(equality_expression_node, sub_expression)
            while(check("==") or check("!=")) do
                table.insert(equality_expression_node, next_token())
                table.insert(equality_expression_node, parse_relational_expression())
            end

            return equality_expression_node
        end

        return sub_expression
    end

    function parse_relational_expression()
        local sub_expression = parse_shift_expression()
        if(check("<") or check("<=") or check(">") or check(">=")) then
            local relational_expression_node = new("RELATIONAL_EXPRESSION")
            table.insert(relational_expression_node, sub_expression)
            while(check("<") or check("<=") or check(">") or check(">=")) do
                table.insert(relational_expression_node, next_token())
                table.insert(relational_expression_node, parse_shift_expression())
            end

            return relational_expression_node
        end

        return sub_expression
    end

    function parse_shift_expression()
        local sub_expression = parse_sum_expression()
        if(check("<<") or check(">>")) then
            local shift_expression_node = new("SHIFT_EXPRESSION")
            table.insert(shift_expression_node, sub_expression)
            while(check("<<") or check(">>")) do
                table.insert(shift_expression_node, next_token())
                table.insert(shift_expression_node, parse_sum_expression())
            end

            return shift_expression_node
        end

        return sub_expression
    end

    function parse_parameter()
        local parameter_node = new("PARAMETER")
        parameter_node.type_specifier = parse_type_specifier()
        parameter_node.id = parse_identifier()

        return parameter_node
    end

    function parse_block()
        local block_node = new("BLOCK")

        if accept("{") then
            symbol_table.new_scope()
            while not check("}") do
                table.insert(block_node, parse_statement())
            end
            expect("}")
            symbol_table.exit_scope()
        else
            Diagnostics.submit(Message.error("Expected '{' to start block", peek_token().pos))
        end

        return block_node
    end

    function parse_statement()
        local statement_node = new("STATEMENT")
        if(check("IF")) then
            statement_node.child = parse_unmatched_statement()
        else
            statement_node.child = parse_non_if_statement()
        end
        return statement_node
    end

    function parse_non_if_statement()
        local non_if_statement_node = nil
        if(check("TYPE_SPECIFIER") or check("STORAGE_CLASS")) then
            non_if_statement_node = parse_declaration()
            expect(";")
        elseif(check("RETURN")) then
            non_if_statement_node = parse_return()
            expect(";")
        elseif(check("{")) then
            non_if_statement_node = parse_block()
        elseif(check("FOR")) then
            non_if_statement_node = parse_for()
        elseif(check("BREAK")) then
            non_if_statement_node = new("BREAK")
            next_token()
            expect(";")
        elseif(check("CONTINUE")) then
            non_if_statement_node = new("CONTINUE")
            next_token()
            expect(";")
        elseif(check("WHILE")) then
            non_if_statement_node = parse_while()
        elseif(check("SWITCH")) then
            non_if_statement_node = parse_switch()
        elseif(check("CASE")) then
            non_if_statement_node = parse_case()
        elseif(check("DEFAULT")) then
            non_if_statement_node = parse_default()
        elseif(check(";")) then
            non_if_statement_node = new("EMPTY_STATEMENT")
            next_token()
        else
            non_if_statement_node = parse_expression()
            expect(";")
        end

        return non_if_statement_node
    end

    function parse_switch()
        local switch_node = new("SWITCH")
        expect("SWITCH")
        expect("(")
        switch_node.condition = parse_expression()
        expect(")")
        switch_node.block = parse_block()
        return switch_node
    end

    function parse_case()
        local case_node = new("CASE")
        expect("CASE")
        case_node.value = parse_primary_expression()
        expect(":")
        case_node.statement = parse_statement()
        return case_node
    end

    function parse_default()
        local default_node = new("DEFAULT")
        expect("DEFAULT")
        expect(":")
        default_node.statement = parse_statement()
        return default_node
    end

    function parse_while()
        local while_node = new("WHILE")
        expect("WHILE")
        expect("(")
        while_node.condition = parse_expression()
        expect(")")
        while_node.statement = parse_statement()
        return while_node
    end

    function parse_return()
        local return_node = new("RETURN")
        next_token()
        return_node.value = parse_expression()

        return return_node
    end

    function parse_declaration_specifier()
        local declaration_specifier_node = new("DECLARATION_SPECIFIER")

        declaration_specifier_node.storage_class = parse_storage_class_specifier()

        if(check("TYPE_SPECIFIER")) then
                declaration_specifier_node.type_specifier = parse_type_specifier()
        else
            Diagnostics.submit(Message.error(string.format("Invalid declaration specifier: '%s'", peek_token().value), peek_token().pos))
        end

        return declaration_specifier_node
    end

    function parse_struct_or_union_specifier()
        local struct_or_union_specifier_node = new("STRUCT_OR_UNION_SPECIFIER")
        struct_or_union_specifier_node.is_struct = next_token().value == "struct"
        
        if(check("ID")) then
            struct_or_union_specifier_node.id = parse_identifier()
        end
        
        -- Currently, only isolated struct declaration is supported
        if(accept("{")) then
            struct_or_union_specifier_node.declaration = {}
            while(not check("}")) do
                table.insert(struct_or_union_specifier_node.declaration, parse_struct_declaration_list())
                expect(";")
            end
            expect("}")
        end
        return struct_or_union_specifier_node
    end

    function parse_struct_declaration_list()
        local struct_declaration_list_node = new("STRUCT_DECLARATION_LIST")
        struct_declaration_list_node.type_specifier = parse_type_specifier()
        table.insert(struct_declaration_list_node, parse_declarator())
        while(accept(",")) do
            table.insert(struct_declaration_list_node, parse_declarator())
        end
        return struct_declaration_list_node
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
        elseif(multi_check({",", ")"})) then
            Diagnostics.submit(Message.error("Abstract function prototypes are not supported yet", peek_token().pos))
        else
            Diagnostics.submit(Message.error(string.format("Unexpected token: '%s'", peek_token().value), peek_token().pos))
        end

        direct_declarator_node.dimensions = {}
        while(multi_check({"[", "("})) do
            if(accept("[")) then
                if(check("INT") or check("UNSIGNED_INT")) then
                    table.insert(direct_declarator_node.dimensions, next_token().value)
                else
                    if(#direct_declarator_node.dimensions == 0) then
                        table.insert(direct_declarator_node.dimensions, -1)
                    else
                        Diagnostics.submit(Message.error("Array dimensions must be specified for all dimensions except the first one", peek_token().pos))
                    end
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
            elseif(peek_token().value == "enum") then
                type_specifier_node.kind = parse_enum_specifier()
            else
                type_specifier_node.kind = {}
                while(check("TYPE_SPECIFIER")) do
                    table.insert(type_specifier_node.kind, next_token().value)
                end
            end
        else
            error(string.format("Invalid type specifier: '%s'", peek_token()))
        end

        return type_specifier_node
    end

    function parse_enum_specifier()
        local enum_specifier_node = new("ENUM_SPECIFIER")
        expect("TYPE_SPECIFIER")
        enum_specifier_node.id = parse_identifier()
        if(accept("{")) then
            enum_specifier_node.declaration = parse_enum_declaration_list()
            expect("}")
        end
        return enum_specifier_node
    end

    function parse_enum_declaration_list()
        local enum_declaration_list_node = new("ENUM_DECLARATION_LIST")
        table.insert(enum_declaration_list_node, parse_enum_member_declaration())
        while(accept(",")) do
            table.insert(enum_declaration_list_node, parse_enum_member_declaration())
        end
        return enum_declaration_list_node
    end


    function parse_enum_member_declaration()
        local enum_member_declaration_node = new("ENUM_MEMBER_DECLARATION")
        enum_member_declaration_node.id = parse_identifier()
        if(accept("=")) then
            if(check("INT")) then
                enum_member_declaration_node.value = next_token().value
            else
                error("Can only assign constant integer values to enum members")
            end
        end
        return enum_member_declaration_node
    end


    function parse_struct_declaration()
        local struct_declaration_node = new("STRUCT_DECLARATION")
        -- if(multi_check({"void", "char", "int", "struct", "union"})) then
        --     struct_declaration_node.type_specifier = parse_type_specifier()
        -- else
        --     error(string.format("Invalid struct declaration type: '%s'", peek_token()))
        -- end

        struct_declaration_node.struct_declarator_list = parse_struct_declarator_list()
        
        error()
    end

    function parse_struct_declarator_list()
        local struct_declarator_list_node = new("STRUCT_DECLARATOR_LIST")
        table.insert(struct_declarator_list_node, parse_declarator())
        while(accept(",")) do
            table.insert(struct_declarator_list_node, parse_declarator())
        end
        return struct_declarator_list_node
    end

    function parse_storage_class_specifier()
        local storage_class_specifier_node = new("STORAGE_CLASS_SPECIFIER")
        if(check("STORAGE_CLASS")) then
            storage_class_specifier_node.kind = next_token().value
        else
            storage_class_specifier_node.kind = "auto"
        end
        return storage_class_specifier_node
    end

    function parse_identifier()
        local identifier_node = new("IDENTIFIER")

        local token = next_token()
        identifier_node.pos = token.pos
        --identifier_node.pos = token.pos
        if token.type == TOKEN_TYPES["ID"] then
            identifier_node.id = token.value
        else
            Diagnostics.submit(Message.error("Unexpected identifier: " .. token.value, token.pos))
        end

        return identifier_node
    end

    function parse_sum_expression()

        local term = parse_term()
        if(check("+") or check("-")) then
            local sum_expression_node = new("SUM_EXPRESSION")
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
        if(check("*") or check("/") or check("%")) then
            local multiplicative_expression_node = new("MULTIPLICATIVE_EXPRESSION")
            table.insert(multiplicative_expression_node, factor)

            while check("*") or check("/") or check("%") do
                
                table.insert(multiplicative_expression_node, next_token())
               table.insert(multiplicative_expression_node, parse_cast_expression())
            end

            return multiplicative_expression_node

        end

        return factor
    end

    function parse_cast_expression()
        if(check("(") and multi_check({"TYPE_SPECIFIER", "struct", "union"}, 1)) then
            local cast_expression_node = new("CAST_EXPRESSION")
            expect("(")
            cast_expression_node.type_specifier = parse_type_name()
            cast_expression_node.pointer_level = 0
            while(accept("*")) do
                cast_expression_node.pointer_level = cast_expression_node.pointer_level + 1
            end
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
            if(check("(") and check("TYPE_SPECIFIER", 1)) then
                expect("(")
                unary_expression_node.child = parse_type_name()
                expect(")")
            else
                unary_expression_node.child = parse_unary_expression()
            end
            unary_expression_node.operator = "SIZEOF"

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
        elseif(check("UNSIGNED_INT")) then
            node = new("INT")
            node.is_unsigned = true
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
            Diagnostics.submit(Message.error("Unexpected token: " .. peek_token().value, peek_token().pos))
        end

        return node
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
        local argument_list_node = new("ARGUMENT_LIST")
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

    function parse_matched_statement()
        if(accept("IF")) then
            local if_node = new("IF")
            expect("(")
            if_node.condition = parse_expression()
            expect(")")

            if_node.true_case = parse_matched_statement()
            expect("ELSE")
            if_node.false_case = parse_matched_statement()

            return if_node
        end

        return parse_non_if_statement()
    end

    function parse_unmatched_statement()
        if (accept("IF")) then
            local if_node = new("IF")
            expect("(")
            if_node.condition = parse_expression()
            expect(")")
            if_node.true_case = parse_statement()
            if(accept("ELSE")) then
                local statement_node = new("STATEMENT")
                statement_node.child = parse_unmatched_statement()
                if_node.false_case = statement_node
            end
            return if_node
        else
            return parse_matched_statement()
        end
    end


    function parse_for()
        local for_node = new("FOR")

        expect("FOR")
        expect("(")

        if(check("TYPE_SPECIFIER") or check("STORAGE_CLASS")) then
            for_node.initialization = parse_declaration()
        else
            for_node.initialization = parse_expression()
        end

        expect(";")

        for_node.condition = parse_expression()

        expect(";")

        for_node.update = parse_expression()

        expect(")")

        for_node.statement = parse_statement()

        return for_node
    end

    return parse_program(), symbol_table
end



return Parser