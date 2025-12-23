local util = require('util')
local Node = {type = 'DEFAULT'}

Node.INVERTED_NODE_TYPES = {
    "PROGRAM",
    "STATEMENT",
    "DECLARATION",
    "TYPE_SPECIFIER",
    "IDENTIFIER",
    "EXPRESSION",
    "TERM",
    "FACTOR",
    "INT",
    "PARAMETER_LIST",
    "PARAMETER",
    "ARGUMENT_LIST",
    "FUNCTION_CALL",
    "BLOCK",
    "STATEMENT",
    "LOCAL_DECLARATION",
    "ASSIGNMENT",
    "IF",
    "FOR",
    "WHILE",
    "RETURN",
    "ADDRESS_OF",
    "DEREFERENCE",
    "STRING_LITERAL",
    "CHARACTER",
    "TERNARY",
    "SUM_EXPRESSION",
    "MULTIPLICATIVE_EXPRESSION",
    "INITIALIZER_LIST",
    "DECLARATOR",
    "DIRECT_DECLARATOR",
    "INIT_DECLARATOR",
    "INITIALIZER",
    "DECLARATION_SPECIFIER",
    "CAST_EXPRESSION",
    "UNARY_EXPRESSION",
    "POSTFIX_EXPRESSION",
    "PRIMARY_EXPRESSION",
    "ABSTRACT_DECLARATOR",
    "DIRECT_ABSTRACT_DECLARATOR",
    "PARAMETER_DECLARATION",
    "PARAMETER_LIST",
    "STRUCT_DECLARATION_LIST",
    "STRUCT_OR_UNION_SPECIFIER",
    "STRUCT_DECLARATION",
    "STRUCT_DECLARATOR_LIST",
    "LOGICAL_OR_EXPRESSION",
    "LOGICAL_AND_EXPRESSION",
    "INCLUSIVE_OR_EXPRESSION",
    "INCLUSIVE_XOR_EXPRESSION",
    "INCLUSIVE_AND_EXPRESSION",
    "EQUALITY_EXPRESSION",
    "RELATIONAL_EXPRESSION",
    "SHIFT_EXPRESSION",
    "BREAK",
    "CONTINUE",
    "STORAGE_CLASS_SPECIFIER",
    "TYPE_NAME",
    "SWITCH",
    "CASE",
    "DEFAULT",
    "ENUM_SPECIFIER",
    "ENUM_DECLARATION_LIST",
    "ENUM_MEMBER_DECLARATION",
    "EMPTY_STATEMENT"
}


Node.NODE_TYPES = util.invert_table(Node.INVERTED_NODE_TYPES)
setmetatable(Node.NODE_TYPES, {__index = function (t, x)
    local upper = string.upper(x)
    if(upper ~= x) then
        return t[upper]
    else
        error("Invalid node type: " .. x)
    end
end})
Node.__index = Node
Node.is_node = true


function Node.node_check(n, node_string)
    return n.type == Node.NODE_TYPES[node_string]
end

function Node:new(ty, pos)
    local t = {type=ty, pos=pos}
    setmetatable(t, Node)
    return t
end

return Node