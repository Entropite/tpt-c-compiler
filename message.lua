local util = require("util")

local Message = {}
Message.TYPES = {["INTERNAL_ERROR"] = 1,  ["ERROR"] = 2, ["WARNING"] = 3}
Message.INVERTED_TYPES = util.invert_table(Message.TYPES)
Message.__index = Message

function Message:__tostring()
    return string.format("[%s] %s at row %d, column %d", Message.INVERTED_TYPES[self.type], self.message, self.pos.row, self.pos.col)
end

function Message.error(message, pos)
    return Message:new(Message.TYPES["ERROR"], message, pos)
end

function Message.warning(message, pos)
    return Message:new(Message.TYPES["WARNING"], message, pos)
end

function Message.internal_error(message, pos)
    return Message:new(Message.TYPES["INTERNAL_ERROR"], message, pos)
end

function Message:new(mtype, message, pos)
    pos = pos or {row="unknown", col="unknown"}
    assert(mtype and Message.INVERTED_TYPES[mtype], "Invalid message type")
    assert(message and type(message) == "string", "Message must be a string")
    assert(pos and pos.row and pos.col, "Position must be a table with row and col fields")
    local t = {type = mtype, message = message, pos = pos}
    setmetatable(t, Message)
    return t
end

return Message