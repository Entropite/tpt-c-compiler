-- operand.lua
local util = require("util")

local Operand = {__eq=function(a, b) return a.type == b.type and a.value == b.value end}
Operand.__index = Operand

Operand.INVERTED_PLACE_TYPES = {"IMMEDIATE", "TEMPORARY", "LVALUE"}
Operand.PLACE_TYPES = util.invert_table(Operand.INVERTED_PLACE_TYPES)

function Operand:new(t, v, o)
    t = {type=t, value=v, offset=o}
    setmetatable(t, Operand)
    return t
end

return Operand

