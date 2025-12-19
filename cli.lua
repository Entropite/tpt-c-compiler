local serpent = require("serpent")
local lexer = require("lexer")
local parser = require("parser")
local irv = require("ir")
local codegen = require("codegen")
local type_checker = require("type_checker")
local symbol_table = require("symbol_table")
local util = require("util")

local file = io.open("main.c", "r")
local code = nil
if(file) then
    code = file:read("*all")
    file:close()
else
    error("Failed to open file")
end


-- local success, optional = pcall(function() return codegen:generate(irv:generate_ir_code(type_checker:type_check(parser.parse(lexer.lex(code)), symbol_table), symbol_table), symbol_table) end)

-- if not success then
--     print(optional.msg)
--     print(debug.traceback())
--     local line = util.split_string(code, "\n")[optional.pos.row]
--     local spaces = string.rep(" ", optional.pos.col - 1)

--     print("at row " .. optional.pos.row .. ", column " .. optional.pos.col .. ":\n" .. line .. "\n" .. spaces .. "^")
--     os.exit(1)
-- end

local optional = codegen:generate(irv:generate_ir_code(type_checker:type_check(parser.parse(lexer.lex(code)), symbol_table), symbol_table), symbol_table)
local file = io.open("main.asm", "w")
file:write(optional)
file:close()
