local lpeg = require("lpeg")

-- C lexer
local tokens = {["ID"] = 1, ["NUM"] = 2, ["("] = 3, [")"] = 4, ["{"] = 5, ["}"] = 6, ["IF"] = 7, ["ELSE"] = 8, ["FOR"] = 9, ["WHILE"] = 10, [";"] = 11, ["="] = 12, ["=="] = 13, ["+"] = 14, ["-"] = 15, ["*"] = 16, ["/"] = 17, ["%"] = 18, ["!="] = 19, ["<"] = 20, [">"] = 21, ["<="] = 22, [">="] = 23, ["&&"] = 24, ["||"] = 25, ["!"] = 26}
local inverted_tokens = {}

function invert_tokens()
    for k, v in pairs(tokens) do
        inverted_tokens[v] = k
    end
end

invert_tokens()


local Token = {}
Token.__index = Token

function Token:new(type, value)
    local o = setmetatable({}, Token)
    o.type = type
    o.value = value
    return o
end

function lex(s)
    local loc = lpeg.locale()
    local S = loc.space^0
    local num = lpeg.C(lpeg.R("09")^1) / function(n) return Token:new(tokens["NUM"], tonumber(n)) end

    -- Reserved words
    local reserved = (lpeg.C(lpeg.P("if") + "else" + "for" + "while") * -loc.alnum) / function(r) return Token:new(tokens[string.upper(r)], r) end

    -- Punctuation

    local punctuation = lpeg.C(lpeg.S("(){};")) / function(p) return Token:new(tokens[p], p) end


    -- Operators
    local op1 = lpeg.C(lpeg.S("+-*/%!<=>")) / function(o) return Token:new(tokens[o], o) end

    local op2 = lpeg.C(lpeg.P("&&") + "||" + "==" + "!=" + "<=" + ">=") / function(o) return Token:new(tokens[o], o) end

    local op = op2 + op1
    -- Identifiers

    local id = lpeg.C(-reserved * loc.alpha * loc.alnum^0) / function(i) return Token:new(tokens["ID"], i) end

    local token = S * ((reserved + id + num + punctuation + op) * S)^0
    return {token:match(s)}

    for _, v in ipairs(t) do
        print(inverted_tokens[v.type], v.value)
    end
end

-- Test case that includes all tokens:
lex([[if (x == y) { 
z = 99; 
} else {
     x = 100; 
    }]])

