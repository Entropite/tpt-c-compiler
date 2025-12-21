-- Utility functions

local Utils = {}
Utils.__index = Utils

function Utils.invert_table(table)
    local inverted_table = {}
    for k, v in pairs(table) do 
        inverted_table[v] = k
    end

    for i, v in ipairs(table) do 
        inverted_table[v] = i
    end

    return inverted_table
end

function Utils.split_string(str, delimiter)
    local result = {}
    for match in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end

    return result
end

function Utils.to_int(str)
    if(string.sub(str, #str, #str) == "u") then
        return Utils.to_int(string.sub(str, 1, #str - 1))
    else
        return tonumber(str)
    end
end

function Utils.string_to_array(str)
    local result = {}
    for i = 1, #str do
        table.insert(result, i == #str and 0 or string.format("'%s'", string.sub(str, i, i)))
    end

    return result
end

function Utils.array_to_string(table, delimiter)
    delimiter = delimiter or " "
    local string = ""
    for i, v in ipairs(table) do
        string = string .. tostring(v) .. ((i == #table) and "" or delimiter)
    end
    return string
end

return Utils