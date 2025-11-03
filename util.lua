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

function Utils.array_to_string(table, delimiter)
    delimiter = delimiter or " "
    local string = ""
    for i, v in ipairs(table) do
        string = string .. tostring(v) .. ((i == #table) and "" or delimiter)
    end
    return string
end

return Utils