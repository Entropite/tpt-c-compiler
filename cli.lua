local lexer = require("lexer")
local parser = require("parser")
local irv = require("ir")
local codegen = require("codegen")
local type_checker = require("type_checker")
local symbol_table = require("symbol_table")
local util = require("util")

if(#arg < 1) then
    print("Usage: lua cli.lua input.c output.asm")
    os.exit(1)
end



local file = io.open(arg[1], "r")
local code = nil
if(file) then
    code = file:read("*all")
    file:close()
else
    error("Failed to open file")
end

local asm = codegen:generate(irv:generate_ir_code(type_checker:type_check(parser.parse(lexer.lex(code)), symbol_table)))
local out_file = io.open(arg[2] or string.sub(arg[1], 1, #arg[1] - 2) .. ".asm", "w")
out_file:write(asm)
out_file:close()
