local Type = require("type")
local util = require("util")
local base = Type.base
local pointer = Type.pointer
local func = Type.func


local symbol_table = {}
symbol_table.default_symbol_table = {level=0, tag_symbols={}, ordinary_symbols={["NULL"]={type=Type.pointer(Type.base("VOID")), place={type="i",value=0}},
    ["__print_unsigned_int"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_print_unsigned_int"}},
    ["__print_unsigned_long"]={type=Type.func(Type.base("VOID"), {Type.base("LONG")}), place={is_standard_function=true, type="i",value="__tptcc_fn_print_unsigned_long"}},
    ["__print_signed_long"]={type=Type.func(Type.base("VOID"), {Type.base("LONG")}), place={is_standard_function=true, type="i", value="__tptcc_fn_print_signed_long"}},
    ["__print_signed_int"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_print_signed_int"}},
["putchar"]={type=Type.func(Type.base("VOID"), {Type.base("CHAR")}), place={is_standard_function=true, type="i",value="__tptcc_fn_putchar"}},
["getchar"]={type=Type.func(Type.base("CHAR"), {}), place={is_standard_function=true, type="i",value="__tptcc_fn_getchar"}},
["getchar_nb"]={type=Type.func(Type.base("CHAR"), {}), place={is_standard_function=true, type="i",value="__tptcc_fn_getchar_nb"}},
["__scan_unsigned_int"]={type=Type.func(Type.base("VOID"), {Type.pointer(Type.base("INT"))}), place={is_standard_function=true, type="i",value="__tptcc_fn_scan_unsigned_int"}},
["set_colour"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_set_colour"}},
["set_cursor"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_set_cursor"}},
["__send_raw"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_send_raw"}},
["__set_zero_char"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT"), Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_set_zero_char"}},
["__print_char_array"]={type=Type.func(Type.base("VOID"), {Type.pointer(Type.base("CHAR"))}), place={is_standard_function=true, is_variadic=false, type="i",value="__tptcc_fn_print_char_array"}},
["vscroll"]={type=Type.func(Type.base("VOID"), {}), place={is_standard_function=true, type="i",value="__tptcc_fn_vscroll"}},
["hscroll"]={type=Type.func(Type.base("VOID"), {}), place={is_standard_function=true, type="i",value="__tptcc_fn_hscroll"}},
["set_terminal_mode"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_set_terminal_mode"}},
["get_terminal_mode"]={type=Type.func(Type.base("INT"), {}), place={is_standard_function=true, type="i",value="__tptcc_fn_get_terminal_mode"}},
["set_text_colour"]={type=Type.func(Type.base("VOID"), {Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_set_text_colour"}},
["set_hrange"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i", value="__tptcc_fn_set_hrange"}},
["set_vrange"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i", value="__tptcc_fn_set_vrange"}},
["plot"]={type=Type.func(Type.base("VOID"), {Type.base("INT"), Type.base("INT"), Type.base("INT")}), place={is_standard_function=true, type="i",value="__tptcc_fn_plot"}},
["BLACK"]={type=Type.base("INT"), place={type="i",value=0}},
["DARK_BLUE"]={type=Type.base("INT"), place={type="i",value=1}},
["DARK_GREEN"]={type=Type.base("INT"), place={type="i",value=2}},
["DARK_CYAN"]={type=Type.base("INT"), place={type="i",value=3}},
["DARK_RED"]={type=Type.base("INT"), place={type="i",value=4}},
["DARK_MAGENTA"]={type=Type.base("INT"), place={type="i",value=5}},
["DARK_YELLOW"]={type=Type.base("INT"), place={type="i",value=6}},
["GREY"]={type=Type.base("INT"), place={type="i",value=7}},
["DARK_GREY"]={type=Type.base("INT"), place={type="i",value=8}},
["BLUE"]={type=Type.base("INT"), place={type="i",value=9}},
["GREEN"]={type=Type.base("INT"), place={type="i",value=10}},
["CYAN"]={type=Type.base("INT"), place={type="i",value=11}},
["RED"]={type=Type.base("INT"), place={type="i",value=12}},
["MAGENTA"]={type=Type.base("INT"), place={type="i",value=13}},
["YELLOW"]={type=Type.base("INT"), place={type="i",value=14}},
["WHITE"]={type=Type.base("INT"), place={type="i",value=15}},
["TERM_ENABLE_NL"]={type=Type.base("INT"), place={type="i",value=0x20}},
["TERM_ENABLE_TERM_MODE_SCROLL"]={type=Type.base("INT"), place={type="i",value=0x10}},
["TERM_ENABLE_SCROLLMASK"]={type=Type.base("INT"), place={type="i",value=0x08}},
["TERM_ENABLE_ROW_ORIENTED"]={type=Type.base("INT"), place={type="i",value=0x04}},
["TERM_ENABLE_ENABLE_COLOUR"]={type=Type.base("INT"), place={type="i",value=0x02}},
["TERM_ENABLE_TERM_MODE"]={type=Type.base("INT"), place={type="i",value=0x01}},
["TERM_DEFAULT"]={type=Type.base("INT"), place={type="i",value=0x25}}}
}


symbol_table.tag = "t"
symbol_table.ordinary = "o"

symbol_table.__index = symbol_table

function symbol_table.reset()
    symbol_table.current_scope = util.deep_copy(symbol_table.default_symbol_table)
end

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
    local new_scope = {level = symbol_table.current_scope.level + 1, name = id, parent = symbol_table.current_scope, tag_symbols = {}, ordinary_symbols = {}}
    symbol_table.current_scope["s" ..id] = new_scope
    symbol_table.current_scope = new_scope
end

function symbol_table.exit_scope()
    symbol_table.current_scope = symbol_table.current_scope.level == 0 and symbol_table.current_scope or symbol_table.current_scope.parent
end

function symbol_table.get_encompassing_function()
    local temp_scope = symbol_table.current_scope
    while temp_scope.level > 1 do
        temp_scope = temp_scope.parent
    end

    return temp_scope
end

function symbol_table.search_from_scope(scope, id, namespace)
    local temp_scope = scope
    while not symbol_table.namespace_get[namespace](temp_scope, id) and temp_scope.level > 0 do
        temp_scope = temp_scope.parent
    end


    return symbol_table.namespace_get[namespace](temp_scope, id)
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
        -- Diagnostics.submit(Message.internal_error(string.format("Symbol '%s' has already been defined", id)))
        error(string.format("Symbol '%s' has already been defined", id))
    else
        symbol_table.set_symbol(id, symbol, namespace)
    end
end
    

symbol_table.reset()

return symbol_table