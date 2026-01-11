local lexer = require("lexer")
local parser = require("parser")
local irv = require("ir")
local codegen = require("codegen")
local type_checker = require("type_checker")
local symbol_table = require("symbol_table")
local util = require("util")

local usage = "Usage: lua cli.lua input.c [--output output.asm] [--size total-memory-size] [--offset offset]" 
if(#arg < 1) then
    print(usage)
    os.exit(1)
end

local output_name = string.sub(arg[1], 1, #arg[1] - 2) .. ".asm"


for arg_idx = 2, #arg - 1, 2 do
    if arg[arg_idx] == "--offset" then
        local offset = tonumber(arg[arg_idx + 1])
        if not offset then
            error("Invalid offset argument: '"..arg[arg_idx + 1].."'")
        end
        codegen.global_addr = codegen.global_addr + offset
    elseif arg[arg_idx] == "--size" then
        local size = tonumber(arg[arg_idx + 1])
        if not size then
            error("Invalid size argument: '"..arg[arg_idx + 1].."'")
        end
        codegen.size = size - 1
    elseif arg[arg_idx] == "--output" then
        output_name = arg[arg_idx + 1]
    end
end

local file = io.open(arg[1], "r")
local code = nil
if(file) then
    code = file:read("*all")
    file:close()
else
    error("Failed to open file")
end

local asm = codegen:generate(irv:generate_ir_code(type_checker:type_check(parser.parse(lexer.lex(code), symbol_table))))
local out_file = io.open(output_name, "w")
out_file:write(asm)
out_file:close()
