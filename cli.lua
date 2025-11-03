-- Remember that your LUA_PATH and LUA_CPATH environment variables have been configured

local serpent = require("serpent")
local lexer = require("lexer")
local parser = require("parser")
local irv = require("ir")
local codegen = require("codegen")




local c = codegen:generate(irv:generate_ir_code(parser.parse(lexer.lex([[
    
    int x = 8;

    int main() {
        fib(0, 1);
    }
    int fib(int a, int b) {
        print_num(a);
        fib(b, a + b);
    }
]]))))

local file = io.open("main.asm", "w")
file:write(c)
file:close()

