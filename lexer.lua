local Token = require("token")
local util = require("util")
local lpeg = require("lpeg")

local Lexer = {}
Lexer.__index = Lexer

-- C lexer


function Lexer.lex(s)
    local loc = lpeg.locale()
    local S = loc.space^0
    local TOKEN_TYPES = Token.TOKEN_TYPES

    s = s:gsub("/%*.-%*/", "") -- remove comments
    -- Integers
    local integers = lpeg.C(lpeg.R("09")^1) / function(n) return Token:new(TOKEN_TYPES["INT"], tonumber(n)) end

    -- Floats
    local floats = lpeg.C(loc.digit^1 * "." * loc.digit^1) / function(f) return Token:new(TOKEN_TYPES["FLOAT"], tonumber(f)) end

    -- Reserved words
    local reserved = (lpeg.C(lpeg.P("if") + "else" + "for" + "while" + "return") * -loc.alnum) / function(r) return Token:new(TOKEN_TYPES[string.upper(r)], r) end

    -- Type specifiers
    local type_specifier = (lpeg.C(lpeg.P("int") + "char" + "void" + "struct" + "union") * -loc.alnum) / function(ts) return Token:new(TOKEN_TYPES["TYPE_SPECIFIER"], ts) end

    local storage_class = (lpeg.C(lpeg.P("auto") + "register" + "static") * -loc.alnum) / function(sc) return Token:new(TOKEN_TYPES["STORAGE_CLASS"], sc) end
    -- Punctuation
    local punctuation = lpeg.C(lpeg.S("(){};,[]")) / function(p) return Token:new(TOKEN_TYPES[p], p) end


    -- Operators
    local non_bool_ops = lpeg.C(lpeg.P("++") + lpeg.P("--") + lpeg.S("+-*/%!<=>&?:")) / function(o) return Token:new(TOKEN_TYPES[o], o) end

    local bool_ops = lpeg.C(lpeg.P("&&") + "||" + "==" + "!=" + "<=" + ">=") / function(o) return Token:new(TOKEN_TYPES[o], o) end

    local op = non_bool_ops + bool_ops
    -- Identifiers

    local id = lpeg.C(-(reserved + type_specifier) * (loc.alpha + "_") * (loc.alnum + "_")^0) / function(i) return Token:new(TOKEN_TYPES["ID"], i) end

    -- String Literals
    local string_lit = lpeg.C(lpeg.P("\"") * (lpeg.P(1) - "\"")^0 * "\"") / function(s) return Token:new(TOKEN_TYPES["STRING_LITERAL"], s) end

    local character = lpeg.C(lpeg.P("'") * (lpeg.P(1) - "'") * "'") / function(s) return Token:new(TOKEN_TYPES["CHARACTER"], s) end

    -- LPEG is greedy so floats must be checked before integers else, integers will match the integer part of the float
    local token = S * ((reserved + type_specifier + id + string_lit + character + floats + integers + punctuation + op) * S)^0
    
    tokens = {token:match(s)}
    setmetatable(tokens, {__tostring = function(s) return util.array_to_string(s, " ") end })

    table.insert(tokens, Token:new(TOKEN_TYPES["EOF"], "EOF"))

    return tokens
end

return Lexer


-- -- Test case that includes all tokens:
-- t = lex([[int myfunc(){if(2 * 2){};}]])


-- print("Parsing...")
-- local parsed = parse(t)

-- function print_tree(node, indent)
--     if not node then return end

--     if type(node) == "table" then
--         print(string.rep(" ", indent) .. INVERTED_NODE_TYPES[node.type])
--         for k, v in pairs(node) do
--             print_tree(v, indent + 4)
--         end
--     end
-- end
-- print(type(parsed))
-- print_tree(parsed, 0)


