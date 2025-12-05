local util = require('util')
local Token = {}
Token.TOKEN_TYPES = {["ID"] = 1, ["INT"] = 2, ["FLOAT"] = 3, ["("] = 4, [")"] = 5, ["{"] = 6, ["}"] = 7, ["IF"] = 8, ["ELSE"] = 9, ["FOR"] = 10, ["WHILE"] = 11, [";"] = 12, ["="] = 13, ["=="] = 14, ["+"] = 15, ["-"] = 16, ["*"] = 17, ["/"] = 18, ["%"] = 19, ["!="] = 20, ["<"] = 21, [">"] = 22, ["<="] = 23, [">="] = 24, ["&&"] = 25, ["||"] = 26, ["!"] = 27, ["TYPE_SPECIFIER"] = 28, ["EOF"] = 29, [","] = 30, ["RETURN"] = 31, ["["]=32, ["]"]=33, ["STRING_LITERAL"]=34, ["&"]=35, ["CHARACTER"]=36, ["?"]=37, [":"]=38, ["STORAGE_CLASS"]=39, ["++"]=40, ["--"]=41}


Token.INVERTED_TOKENS = util.invert_table(Token.TOKEN_TYPES)
Token.__index = Token

function Token:__tostring()
    return "[" .. self.INVERTED_TOKENS[self.type] .. "] " .. self.value
end

function Token:new(type, value)
    local o = setmetatable({}, self)
    o.type = type
    o.value = value
    return o
end

return Token