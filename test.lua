package.path = "C:/Users/Jacob/AppData/Roaming/luarocks/share/lua/5.4/?.lua;" .. package.path
local luaunit = require('luaunit')

local lexer = require('lexer')

TestLexer = {}

function TestLexer:test_simple()
    luaunit.assertEquals(tostring(lexer.lex([[
    int main() {
        int i = 5+5;
        int j = 9;
        for(int k = 0; k < i * j; k++) {
            j = j - 1;
        }
        return 1 + i / j + 2 * (1 +j); }
]])),"[TYPE_SPECIFIER] int [ID] main [(] ( [)] ) [{] { [TYPE_SPECIFIER] int [ID] i [=] = [INT] 5 [+] + [INT] 5 [;] ; [TYPE_SPECIFIER] int [ID] j [=] = [INT] 9 [;] ; [FOR] for [(] ( [TYPE_SPECIFIER] int [ID] k [=] = [INT] 0 [;] ; [ID] k [<] < [ID] i [*] * [ID] j [;] ; [ID] k [+] + [+] + [)] ) [{] { [ID] j [=] = [ID] j [-] - [INT] 1 [;] ; [}] } [ID] return [INT] 1 [+] + [ID] i [/] / [ID] j [+] + [INT] 2 [*] * [(] ( [INT] 1 [+] + [ID] j [)] ) [;] ; [}] } [EOF] EOF")
end

os.exit(luaunit.LuaUnit.run())