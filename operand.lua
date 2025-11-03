-- operand.lua
local util = require("util")

local Operand = {}
Operand.__index = Operand

Operand.INVERTED_PLACE_TYPES = {"IMMEDIATE", "TEMPORARY", "LVALUE"}
Operand.PLACE_TYPES = util.invert_table(Operand.INVERTED_PLACE_TYPES)

function Operand:new(t, v)
    t = {type=t, value=v}
    setmetatable(t, Operand)
    return t
end

return Operand

