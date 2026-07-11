-- operand.lua
local util = require("util")

local Operand = {label=0, temp=0, global=0, __eq=function(a, b) return a.type == b.type and a.value == b.value and a.offset == b.offset end} -- bitsize is not included in the equality metamethod

function Operand.copy_place(place)
    return Operand:new(place.type, place.value, place.bitsize)
end

function Operand:next_stack(size, method)
    assert(method.local_size ~= nil, "Method local size is nil")
    local result = method.local_size
    method.local_size = result + size
    return result
end

function Operand:next_temp()
    self.temp = self.temp + 1
    return self.temp
end

function Operand:next_global(size)
    local temp = self.global
    self.global = temp + size
    return temp
end

function Operand:next_label()
    local temp = self.label
    self.label = self.label + 1
    return temp
end

Operand.__index = Operand
Operand.lvalue_operands = {["l"]=1,["p"]=2,["g"]=3, ["pr"]=4, ["vr"]=5} -- has lvalue; may or may not have a register
Operand.mem_lvalue_operands = {["l"]=1, ["p"]=1, ["g"]=1, ["vr"]=1} -- has lvalue but doesn't have a register
Operand.reg_rvalue_operands = {["t"]=1, ["r"]=2, ["vr"]=3} -- has r value; has a register
Operand.rvalue_operands = {["i"]=1, ["t"]=1, ["r"]=1, ["vr"]=1} -- has r value without lvalue; may or may not have a register

Operand.operand = {
    l=function(s, method) return Operand:new("l", Operand:next_stack(s, method)) end, -- local variable
    p=function(v) return Operand:new("p", v) end,                   -- parameter
    g=function(s) return Operand:new("g", Operand:next_global(s)) end, -- global variable
    pr=function() return Operand:new("pr", Operand:next_temp()) end,    -- pointer held in register (thought of as an lvalue temporary)
    i=function(v, bitsize) return Operand:new("i", v, bitsize) end,                      -- immediate
    t=function(bitsize) return Operand:new("t", Operand:next_temp(), bitsize) end,    -- temporary    
    r=function(v) return Operand:new("r", v) end,                        -- binded register
    lb=function() return Operand:new("i", string.format(".label_%d", Operand:next_label())) end, --label
    vr=function() return Operand:new("vr", Operand:next_temp()) end -- variable register (used for variables residing in registers), should not be confused with "virtual register"
}

function Operand:new(t, v, bitsize)
    bitsize = bitsize or 16
    t = {type=t, value=v, offset=nil, bitsize=bitsize}
    setmetatable(t, Operand)
    return t
end

return Operand

