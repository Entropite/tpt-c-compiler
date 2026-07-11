local Token = require("token")
local util = require("util")


local lpeg_installed, lpeg = pcall(function() return require("lpeg") end)

if(not lpeg_installed) then
    lpeg = require("lipeg")
end

local Lexer = {}
Lexer.__index = Lexer

-- C lexer


-- very simple preprocessor
-- not supported yet
-- function substitute_includes(code)
--     local lines = {}
--     for line in code:gmatch("[^\r\n]+") do
--         local includes = line:match("#include <(%w.+)>")
--         if(includes) then
--             local file = io.open("includes/" .. includes, "r")
--             if(file) then
--                 lines[#lines + 1] = file:read()
--                 file:close()
--             else
--                 error("Library does not exist: " .. includes)
--             end
--         else
--             includes = line:match("#include \"(%w.+)\"")
--             if(includes) then
--                 local file = io.open("includes/" .. includes, "r")
--                 if(file) then
--                     lines[#lines + 1] = substitute_includes(file:read())
--                     file:close()
--                 else
--                     error("File does not exist: " .. includes)
--                 end
--             else
--                 lines[#lines + 1] = line
--             end
--         end
--     end

    
--     return table.concat(lines, "\n")

-- end

function Lexer.lex(s)
    local loc = lpeg.locale()
    local S = lpeg.S(" \n\t\r")^0
    local TOKEN_TYPES = Token.TOKEN_TYPES
    local INT_LITERAL_SUFFIXES = Token.INT_LITERAL_SUFFIXES

    local last_newline_pos = 0
    local rows = 1

    local processed_code = {}
    
    local escape_map = {
        ["'\\n'"] = 10,
        ["'\\\\'"] = "'\\'"
    }

    local string_escape_map = {
        ["\\n"] = "\n",
        ["\\\\"] = "\\"
    }

    function check_for_escape_sequence(ch)
        
        if(escape_map[ch]) then
            return escape_map[ch]
        else
            return ch
        end
    end

    function check_for_escape_sequences_string(str)
        
        return str:gsub("\\.", function(ch) return string_escape_map[ch] end)
    end

    local new_lines = {0}
    for i=1, #s do
        if(string.byte(s, i) == 10) then
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
    local integers = lpeg.C(lpeg.R("09")^1 * lpeg.S("uUlL")^-1)
    integers = lpeg.Cp() * integers / function(pos, n) 
        local int_type = INT_LITERAL_SUFFIXES[string.sub(n, #n, #n)]
        local int_value = nil
        if(not int_type) then
            int_value = util.to_int(n)
            if(int_value > 65535) then
                int_type = TOKEN_TYPES["LONG"]
            else
                int_type = TOKEN_TYPES["INT"]
            end
        else
            int_value = util.to_int(string.sub(n, 1, #n - 1))
        end
        return Token:new(int_type, int_value, get_pos(pos)) end

    local hex_integers = lpeg.C(lpeg.P("0x") * lpeg.R("09", "af", "AF")^1 * lpeg.S("uUlL")^-1)
    hex_integers = lpeg.Cp() * hex_integers / function(pos, n) 
        
        local hex_type = INT_LITERAL_SUFFIXES[string.sub(n, #n, #n)]
        local hex_value = nil
        if(not hex_type) then
            hex_value = util.to_int(n)
            if(hex_value > 65535) then
                hex_type = TOKEN_TYPES["LONG"]
            else
                hex_type = TOKEN_TYPES["INT"]
            end
        else
            hex_value = util.to_int(string.sub(n, 1, #n - 1))
        end
        return Token:new(hex_type, hex_value, get_pos(pos)) end
    
    -- Floats (not supported yet)
    local floats = lpeg.C(loc.digit^1 * "." * loc.digit^1) 
    floats = lpeg.Cp() * floats / function(pos, f) return Token:new(TOKEN_TYPES["FLOAT"], tonumber(f), get_pos(pos)) end

    -- Reserved words
    local reserved = (lpeg.C(lpeg.P("if") + "else" + "for" + "while" + "return" + "break" + "continue" + "switch" + "case" + "default" + "asm") * -(loc.alnum + "_")) 
    reserved = lpeg.Cp() * reserved / function(pos, r) return Token:new(TOKEN_TYPES[string.upper(r)], r, get_pos(pos)) end

    -- Type specifiers
    local type_specifier = (lpeg.C(lpeg.P("int") + "char" + "void" + "long" + "unsigned" + "signed"+ "struct" + "union" + "enum") * -(loc.alnum + "_")) 
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
    
    local succ, p, tokens
    if(lpeg_installed) then
        tokens = {token:match(s)}
    else
        succ, p, tokens = token:match(s, 1, {size=0})
        util.resize_list(tokens, tokens.size)
    end

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