-- Remember that your LUA_PATH and LUA_CPATH environment variables have been configured

local serpent = require("serpent")
local lexer = require("lexer")
local parser = require("parser")
local irv = require("ir")
local codegen = require("codegen")
local type_checker = require("type_checker")


local c = codegen:generate(irv:generate_ir_code(type_checker:type_check(parser.parse(lexer.lex([[
    int x(){
        int a = 5;
        print_num(a + 5);
    }

    int (*y)() = x;
    int z = y();

]])))))
-- local c = codegen:generate(irv:generate_ir_code(type_checker:type_check(parser.parse(lexer.lex([[
--     char *a[][] = {{"ab", "ef"}, {"cd"}};
-- ]])))))

-- local c = codegen:generate(irv:generate_ir_code(parser.parse(lexer.lex([[
--     int a[3] = {1, 99, 3};
--     int main() {
--         print_num(*(&a+1));
--     }
-- ]]))))

local file = io.open("main.asm", "w")
file:write(c)
file:close()

