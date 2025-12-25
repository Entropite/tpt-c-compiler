local util = require('util')

local Type = {}
-- pointers have a "points_to" field that is a Type object
-- arrays have a length field

Type.INVERTED_KINDS = {
    "VOID",
    "CHAR",
    "INT",
    "STRUCT",
    "UNION",
    "POINTER",
    "ARRAY",
    "FUNCTION"
}
Type.BASE_KINDS = {
    ["VOID"]=1,
    ["CHAR"]=1,
    ["INT"]=1,
    ["FUNCTION"]=1,
    ["STRUCT"]=1,
    ["UNION"]=1,
    ["ENUM"]=1
}

Type.KINDS = util.invert_table(Type.INVERTED_KINDS)
Type.__index = Type

function Type:new(t)
    local o = setmetatable(t or {}, Type)
    return o
end

function Type.same_type_chain(type1, type2, allow_length_mismatch)
    allow_length_mismatch = allow_length_mismatch or false
    while(type1 ~= nil and type2 ~= nil) do
        if(type1.kind ~= type2.kind or (not allow_length_mismatch and type1.length ~= type2.length)) then
            return false
        end
        type1 = type1.points_to
        type2 = type2.points_to
    end

    return type1 == type2 -- both are nil
end

    function Type.base(kind)
        if(type(kind) == "table") then
            if(#kind == 1) then
                return Type:new({kind = Type.KINDS[string.upper(kind[1])], signed = true})
            elseif(#kind == 2) then
                -- first kind is signedness
                -- second kind is the base type
                local first_kind = string.upper(kind[1])
                local second_kind = string.upper(kind[2])
                assert((first_kind == "SIGNED" or first_kind == "UNSIGNED") and second_kind == "INT", "Invalid type specifier")
                return Type:new({kind = Type.KINDS[second_kind], signed = first_kind == "SIGNED"})
            else
                error()
            end
        else
            return Type:new({kind = Type.KINDS[string.upper(kind)], signed = true})
        end
    end

    function Type.pointer(target_type)
        return Type:new({kind = Type.KINDS["POINTER"], points_to = target_type})
    end

    function Type.array(length, target_type)
        return Type:new({kind = Type.KINDS["ARRAY"], length = length, points_to = target_type})
    end

    function Type.func(return_type, parameter_types)
        return Type:new({kind = Type.KINDS["FUNCTION"], return_type = return_type, parameter_types = parameter_types})
    end

    function Type.struct(id, members)
        return Type:new({kind = Type.KINDS["STRUCT"], id = id, members = members or {}})
    end
    function Type.enum(id, members)
        return Type:new({kind = Type.KINDS["ENUM"], id = id, members = members or {}})
    end

    function Type.union(id, members)
        return Type:new({kind = Type.KINDS["UNION"], id = id, members = members or {}})
    end

    function Type.is_base_type(type)
        return Type.BASE_KINDS[string.upper(Type.INVERTED_KINDS[type.kind])]
    end

    function Type.to_string(type)
        if(type == nil) then
            return "?"
        end

        if(type.kind == Type.KINDS["POINTER"]) then
            return Type.to_string(type.points_to) .. "*"
        elseif(type.kind == Type.KINDS["ARRAY"]) then
            return Type.to_string(type.points_to) .. "[" .. (type.length >= 0 and type.length or "?") .. "]"
        else
            return Type.INVERTED_KINDS[type.kind]
        end
    end

    function Type.to_string_pretty(type)
        if(type == nil) then
            return "?"
        end

        local chain = {}
        while(type ~= nil) do
            table.insert(chain, type)
            type = type.points_to
        end

        local result = ""
        local i = #chain
        type = chain[i]
        while(type ~= nil) do
            local array_string = ""
            while(type ~= nil and type.kind == Type.KINDS["ARRAY"]) do
                array_string = "[" .. (type.length >= 0 and type.length or "?") .. "]" .. array_string
                i = i - 1
                type = chain[i]
                
            end

            result = result .. array_string
            if(type == nil) then
                break
            elseif(type.kind == Type.KINDS["POINTER"]) then
                result = result .. "*"
            elseif(type.kind == Type.KINDS["FUNCTION"]) then
                result = result .. "FUNCTION(("
                for _, param in ipairs(type.parameter_types) do
                    result = result .. Type.to_string_pretty(param) .. ", "
                end
                result = result .. ") -> " .. Type.to_string_pretty(type.return_type) .. ")"
            elseif(Type.INVERTED_KINDS[type.kind]) then
                result = result .. Type.INVERTED_KINDS[type.kind]
            else
                local potential_symbol = get_symbol(type.kind, symbol_table.ordinary)
                if(potential_symbol) then
                    result = result .. Type.to_string_pretty(potential_symbol.type)
                else
                    error()
                end
            end

            i = i - 1
            type = chain[i]
        end

        return result
    end


return Type