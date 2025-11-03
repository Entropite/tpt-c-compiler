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
    "RETURN"
}


Node.NODE_TYPES = util.invert_table(Node.INVERTED_NODE_TYPES)
setmetatable(Node.NODE_TYPES, {__index = function (t, x)
    return t[string.upper(x)]
end})
Node.__index = Node





function Node:new(ty)
    local t = {type=ty}
    setmetatable(t, Node)
    return t
end

return Node