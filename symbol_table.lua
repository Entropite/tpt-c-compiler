local Type = require("type")
local base = Type.base
local pointer = Type.pointer
local func = Type.func

local symbol_table = {level=0, tag_symbols={}, ordinary_symbols={["NULL"]={type=Type.pointer(Type.base("VOID")), place={type="i",value=0}},
    ["__print_unsigned_int"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__print_unsigned_int"}},
["__print_signed_int"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__print_signed_int"}},
["putchar"]={type=Type.func(Type.base("VOID"), {Type.base("CHAR")}), place={is_standard_function=true, type="i",value="putchar"}},
["getchar"]={type=Type.func(Type.base("CHAR"), {}), place={is_standard_function=true, type="i",value="getchar"}},
["__scan_unsigned_int"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__scan_unsigned_int"}},
["set_colour"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="set_colour"}},
["set_cursor"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="set_cursor"}},
["__print_char_array"]={type=Type.func(Type.base("VOID"), {Type.pointer(Type.base("CHAR"))}), place={is_standard_function=true, is_variadic=false, type="i",value="__print_char_array"}}}}

symbol_table.current_scope = symbol_table
symbol_table.tag = "t"
symbol_table.ordinary = "o"

symbol_table.namespace_get = {
    [symbol_table.tag]=function(scope, id) return scope.tag_symbols[id] end,
    [symbol_table.ordinary]=function(scope, id) return scope.ordinary_symbols[id] end
}

symbol_table.namespace_set = {
    [symbol_table.tag]=function(scope, id, symbol) scope.tag_symbols[id] = symbol end,
    [symbol_table.ordinary]=function(scope, id, symbol) scope.ordinary_symbols[id] = symbol end
}

function symbol_table.new_scope(id)
    id = id or "default"
    local new_scope = {level = symbol_table.current_scope.level + 1, parent = symbol_table.current_scope, tag_symbols = {}, ordinary_symbols = {}}
    symbol_table.current_scope["s" ..id] = new_scope
    symbol_table.current_scope = new_scope
end

function symbol_table.exit_scope()
    symbol_table.current_scope = symbol_table.current_scope.level == 0 and symbol_table.current_scope or symbol_table.current_scope.parent
end

function symbol_table.get_symbol(id, namespace)
    local temp_scope = symbol_table.current_scope
    while not symbol_table.namespace_get[namespace](temp_scope, id) and temp_scope.level > 0 do
        temp_scope = temp_scope.parent
    end

    return symbol_table.namespace_get[namespace](temp_scope, id), temp_scope.level
end

function symbol_table.set_symbol(id, symbol, namespace)
    symbol_table.namespace_set[namespace](symbol_table.current_scope, id, symbol)
end

function symbol_table.add_symbol(id, symbol, namespace)
    local sym = symbol_table.namespace_get[namespace](symbol_table.current_scope, id)
    if(sym) then
        if(sym.is_prototype) then
            return
        end
        error(string.format("Symbol '%s' has already been defined", id))
    else
        symbol_table.set_symbol(id, symbol, namespace)
    end
end
    

return symbol_table