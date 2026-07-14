local lexer = require("lexer")
local parser = require("parser")
local irv = require("ir")
local codegen = require("codegen")
local type_checker = require("type_checker")
local symbol_table = require("symbol_table")
local util = require("util")
local tac_arithmetic_lowerer = require("tac_arithmetic_lowerer")
local Standard_Library = require("standard_library")
local preprocessor = require("preprocessor")

if(_VERSION ~= "Lua 5.4") then
    print("[WARNING] This compiler requires Lua 5.4. You are using Lua " .. _VERSION .. ". The compiler may not work as expected.")
end

local usage = "Usage: lua cli.lua input.c [input2.c ...]  [--output output.asm] [--size total-memory-size] [--term-width width] [--term-height height] [--offset offset] [--symbols symbols.json]" 
if(#arg < 1) then
    print(usage)
    os.exit(1)
end

local output_name = string.sub(arg[1], 1, #arg[1] - 2) .. ".asm"
local export_symbols = false
local export_symbols_filename
local breakpoints = {}

local file = io.open(arg[1], "r")
local code = {}
if(file) then
    table.insert(code, file:read("*all"))
    file:close()
else
    error("Failed to open file")
end

local arg_start_idx = 2

while arg_start_idx <= #arg do
    if(#arg[arg_start_idx] < 2 or string.sub(arg[arg_start_idx], 1, 2) ~= "--") then
        local aux_file = io.open(arg[arg_start_idx], "r")
        if(aux_file) then
            table.insert(code, aux_file:read("*all"))
            aux_file:close()
        else
            error("Failed to open file: " .. arg[arg_start_idx])
        end
    end
    arg_start_idx = arg_start_idx + 1
end

for arg_idx = arg_start_idx, #arg - 1, 2 do
    if arg[arg_idx] == "--offset" then
        local offset = tonumber(arg[arg_idx + 1])
        if not offset then
            error("Invalid offset argument: '"..arg[arg_idx + 1].."'")
        end
        codegen.global_addr = codegen.global_addr + offset
    elseif arg[arg_idx] == "--size" then
        local size = tonumber(arg[arg_idx + 1])
        if(size < 1024) then
            print("[WARNING] Size is less than 1024. Remember that the '--size' argument expects the total memory size, not the number of memory rows.")
        end

        if not size then
            error("Invalid size argument: '"..arg[arg_idx + 1].."'")
        end
        codegen.size = size - 1
    elseif arg[arg_idx] == "--output" then
        output_name = arg[arg_idx + 1]
    elseif arg[arg_idx] == "--term-width" then
        local width = tonumber(arg[arg_idx + 1])
        if not width then
            error("Invalid term-width argument: '"..arg[arg_idx + 1].."'")
        end
        codegen.term_width = width
    elseif arg[arg_idx] == "--term-height" then
        local height = tonumber(arg[arg_idx + 1])
        if not height then
            error("Invalid term-height argument: '"..arg[arg_idx + 1].."'")
        end
        codegen.term_height = height
    elseif arg[arg_idx] == "--symbols" then
        export_symbols = true
        export_symbols_filename = arg[arg_idx + 1]
        if not export_symbols_filename then
            error("Exporting symbols requires specifying an output file")
        end
    elseif arg[arg_idx] == "--breakpoints" then
        local breakpoint_string = arg[arg_idx + 1]
        breakpoint_string = string.sub(breakpoint_string, 2, #breakpoint_string - 1)
        local breakpoint_strings = util.split_string(breakpoint_string, ",")
        for _, breakpoint_string in ipairs(breakpoint_strings) do
            breakpoint = tonumber(breakpoint_string)
            if not breakpoint then
                error("Invalid breakpoint argument: '"..breakpoint.."'")
            end
            table.insert(breakpoints, breakpoint)
        end

        table.sort(breakpoints)
    end
end

code = table.concat(code, "\n")

code = preprocessor.preprocess(code)
local temp_file = io.open("temp.c", "w")
temp_file:write(code)
temp_file:close()

local type_checked_ast, included_standard_functions = type_checker.type_check(parser.parse(lexer.lex(code), symbol_table))

-- resolve included standard functions by filling in dependencies
included_standard_functions = Standard_Library.resolve_dependencies(included_standard_functions)


local ir_code = irv.generate_ir_code(type_checked_ast, breakpoints)

tac_arithmetic_lowerer:lower(ir_code.tac)
local asm = codegen:generate(ir_code, symbol_table, included_standard_functions)


local out_file = io.open(output_name, "w")
out_file:write(asm)
out_file:close()

if(export_symbols) then
    local json_installed, json = pcall(function() return require("dkjson") end)
    if(json_installed) then

        local type_exception = function(reason, value, state) return '"NULL"' end

        local json_string = json.encode(symbol_table, {indent=true, exception=type_exception})
        local json_file = io.open(export_symbols_filename, "w")
        json_file:write(json_string)
        json_file:close()
    else        
        print("[ERROR] dkjson not found, symbols cannot be exported to json")
    end
end