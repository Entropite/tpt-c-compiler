-- operand.lua
local util = require("util")

local Operand = {}
Operand.__index = Operand

Operand.INVERTED_PLACE_TYPES = {"IMMEDIATE", "TEMPORARY", "LVALUE"}
Operand.PLACE_TYPES = util.invert_table(Operand.INVERTED_PLACE_TYPES)

function Operand:new(t, v, is_lvalue)
    t = {type=t, value=v, is_lvalue=is_lvalue or false}
    setmetatable(t, Operand)
    return t
end

return Operand

