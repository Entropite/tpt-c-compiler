local Token = require("token")
local util = require("util")
local lpeg = require("lpeg")

local Lexer = {}
Lexer.__index = Lexer

-- C lexer


function Lexer.lex(s)
    local loc = lpeg.locale()
    local S = lpeg.S(" \n\t\r")^0
    local TOKEN_TYPES = Token.TOKEN_TYPES

    local last_newline_pos = 0
    local rows = 1

    function check_for_escape_sequence(ch)
        local escape_map = {
            ["'\\n'"] = 10,
            ["'\\\\'"] = "'\\'"
        }
        if(escape_map[ch]) then
            return escape_map[ch]
        else
            return ch
        end
    end

    function check_for_escape_sequences_string(str)
        local string_escape_map = {
            ["\\n"] = "\n",
            ["\\\\"] = "\\"
        }
        return str:gsub("\\.", function(ch) return string_escape_map[ch] end)
    end

    local new_lines = {0}
    for i=1, #s do
        if(string.sub(s, i, i) == "\n") then
            table.insert(new_lines, i)
        end
    end

    function get_pos(pos)
        -- Get largest new_line position before pos
        local l = 1
        local h = #new_lines
        while l < h do
            local mid = math.floor((l + h + 1) / 2)
            if(new_lines[mid] <= pos) then
                l = mid
            else
                h = mid - 1
            end
        end
        return {row=l, col=pos - new_lines[l]}
    end



    -- s = s:gsub("/%*.-%*/", "") -- remove comments

    local multiline_comments = lpeg.P("/*") * (lpeg.P(1) - lpeg.P("*/"))^0 * lpeg.P("*/")
    local singleline_comments = lpeg.P("//") * (lpeg.P(1) - lpeg.P("\n"))^0

    -- Integers
    local integers = lpeg.C(lpeg.R("09")^1 * lpeg.P("u")^-1) 
    integers = lpeg.Cp() * integers / function(pos, n) return Token:new(string.sub(n, #n, #n) == "u" and TOKEN_TYPES["UNSIGNED_INT"] or TOKEN_TYPES["INT"], util.to_int(n), get_pos(pos)) end

    local hex_integers = lpeg.C(lpeg.P("0x") * lpeg.R("09", "af", "AF")^1 * lpeg.P("u")^-1)
    hex_integers = lpeg.Cp() * hex_integers / function(pos, n) return Token:new(string.sub(n, #n, #n) == "u" and TOKEN_TYPES["UNSIGNED_INT"] or TOKEN_TYPES["INT"], util.to_int(n), get_pos(pos)) end
    
    -- Floats (not supported yet)
    local floats = lpeg.C(loc.digit^1 * "." * loc.digit^1) 
    floats = lpeg.Cp() * floats / function(pos, f) return Token:new(TOKEN_TYPES["FLOAT"], tonumber(f), get_pos(pos)) end

    -- Reserved words
    local reserved = (lpeg.C(lpeg.P("if") + "else" + "for" + "while" + "return" + "break" + "continue" + "switch" + "case" + "default") * -loc.alnum) 
    reserved = lpeg.Cp() * reserved / function(pos, r) return Token:new(TOKEN_TYPES[string.upper(r)], r, get_pos(pos)) end

    -- Type specifiers
    local type_specifier = (lpeg.C(lpeg.P("int") + "char" + "void" + "unsigned" + "signed"+ "struct" + "union" + "enum") * -(loc.alnum + "_")) 
    type_specifier = lpeg.Cp() * type_specifier / function(pos, ts) return Token:new(TOKEN_TYPES["TYPE_SPECIFIER"], ts, get_pos(pos)) end

    local storage_class = (lpeg.C(lpeg.P("auto") + "register" + "static" + "typedef") * -loc.alnum)
    storage_class = lpeg.Cp() * storage_class / function(pos, sc) return Token:new(TOKEN_TYPES["STORAGE_CLASS"], sc, get_pos(pos)) end
    -- Punctuation
    local punctuation = lpeg.C(lpeg.S("(){};,[]")) 
    punctuation = lpeg.Cp() * punctuation / function(pos, p) return Token:new(TOKEN_TYPES[p], p, get_pos(pos)) end


    -- Operators
    local non_bool_ops = lpeg.C(lpeg.P("++") + lpeg.P("--") + lpeg.P("->") + lpeg.P("...") + lpeg.P("<<")*-lpeg.P("=") + lpeg.P(">>")*-lpeg.P("=") + "sizeof" + "+=" + "-=" + "*=" + "/=" + "%=" + "&=" + "|=" + "^=" + "<<=" + ">>=" + lpeg.S("+-*/%!<=>&?:.^|~")) 
    non_bool_ops = lpeg.Cp() * non_bool_ops / function(pos, o) return Token:new(TOKEN_TYPES[string.upper(o)], o, get_pos(pos)) end

    local bool_ops = lpeg.C(lpeg.P("&&") + "||" + "==" + "!=" + "<=" + ">=") 
    bool_ops = lpeg.Cp() * bool_ops / function(pos, o) return Token:new(TOKEN_TYPES[o], o, get_pos(pos)) end

    local op = bool_ops + non_bool_ops
    -- Identifiers

    local id = lpeg.C(-(reserved + type_specifier) * (loc.alpha + "_") * (loc.alnum + "_")^0)
    id = lpeg.Cp() *id / function(pos, i) return Token:new(TOKEN_TYPES["ID"], i, get_pos(pos)) end

    -- String Literals
    local string_lit = lpeg.C(lpeg.P("\"") * (lpeg.P(1) - "\"")^0 * "\"") 
    string_lit = lpeg.Cp() * string_lit / function(pos, s) return Token:new(TOKEN_TYPES["STRING_LITERAL"], check_for_escape_sequences_string(s), get_pos(pos)) end

    local character = lpeg.C(lpeg.P("'") * (lpeg.P(1) - "'")^0 * "'") 
    character = lpeg.Cp() * character / function(pos, s) return Token:new(TOKEN_TYPES["CHARACTER"], check_for_escape_sequence(tostring(s)), get_pos(pos)) end

    local other = lpeg.Cp() * lpeg.C((lpeg.P(1) - lpeg.S(" \n\t\r"))^1) / function(pos, o) return Token:new(TOKEN_TYPES["OTHER"], o, get_pos(pos)) end
    -- LPEG is greedy so floats must be checked before integers else, integers will match the integer part of the float
    local token = S * ((singleline_comments + multiline_comments + reserved + storage_class + op +type_specifier + id + string_lit + character + hex_integers + integers + punctuation + other) * S)^1
    tokens = {token:match(s)}
    setmetatable(tokens, {__tostring = function(s) return util.array_to_string(s, " ") end })

    table.insert(tokens, Token:new(TOKEN_TYPES["EOF"], "EOF", {row=#new_lines, col=1}))

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