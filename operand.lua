-- operand.lua
local util = require("util")

local Operand = {__eq=function(a, b) return a.type == b.type and a.value == b.value and a.offset == b.offset end}
Operand.__index = Operand

function Operand:new(t, v, o)
    t = {type=t, value=v, offset=o}
    setmetatable(t, Operand)
    return t
end

return Operand

