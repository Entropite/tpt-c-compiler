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
    "PARAMETER_LIST"
}


Node.NODE_TYPES = util.invert_table(Node.INVERTED_NODE_TYPES)
setmetatable(Node.NODE_TYPES, {__index = function (t, x)
    return t[string.upper(x)]
end})
Node.__index = Node



function Node.node_check(n, node_string)
    return n.type == Node.NODE_TYPES[node_string]
end

function Node:new(ty)
    local t = {type=ty}
    setmetatable(t, Node)
    return t
end

return Node