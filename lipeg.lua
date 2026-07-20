local util = require("util")


local lipeg = {}
lipeg.__index = lipeg

lipeg.INVERTED_TYPES = {"LITERAL", "SEQUENCE", "CHOICE"}
lipeg.TYPES = util.invert_table(lipeg.INVERTED_TYPES)


function lipeg:__mul(other)
    if(type(other) == "string") then
        other = lipeg.P(other)
    end
    local t = {grammar = {self, other}, match=lipeg.match_sequence}

    setmetatable(t, lipeg)
    return t
end

function lipeg:__sub(other)
    if(type(other) == "string") then
        other = lipeg.P(other)
    end
    
    local t = {grammar = {-other, self}, match=lipeg.match_sequence}
    setmetatable(t, lipeg)
    return t
end

function lipeg:__add(other)
    if(type(other) == "string") then
        other = lipeg.P(other)
    end

    local t = {grammar = {self, other}, match=lipeg.match_choice}

    setmetatable(t, lipeg)
    return t
end

function lipeg:match_repetition(input, pos, captures, count)
    local old_capture_size = captures.size
    local new_pos = pos
    if(count < 0) then
        local i = 1
        for i = 1, -count do
            local success, temp_pos, new_captures = self.grammar[1]:match(input, new_pos, captures)
            new_pos = temp_pos
            captures = new_captures
            if(not success) then
                break
            end
        end
        return true, new_pos, captures
    else
        for i = 1, count do
            local success, temp_pos, new_captures = self.grammar[1]:match(input, new_pos, captures)
            if(success) then
                new_pos = temp_pos
                captures = new_captures
            else
                captures.size = old_capture_size
                return false, pos, captures
            end
        end

        while(true) do
            local temp_success, temp_pos, new_captures = self.grammar[1]:match(input, new_pos, captures)
            if(temp_success) then
                new_pos = temp_pos
                captures = new_captures
            else
                break
            end
        end
        return true, new_pos, captures
    end
end


function lipeg:__pow(other)
    assert(type(other) == "number", "Invalid repetition value")
    local t = {grammar = {self}}
    t.match = function(self, input, pos, captures) return lipeg.match_repetition(t, input, pos, captures, other) end
    setmetatable(t, lipeg)
    return t
end

function lipeg:match_negative_lookahead(input, pos, captures)
    local old_capture_size = captures.size
    local negative_lookahead_success, _, _ = self.grammar[1]:match(input, pos, captures)
    captures.size = old_capture_size
    if(negative_lookahead_success) then
        return false, pos, captures
    else
        return true, pos, captures
    end
end

function lipeg:__unm()
    local t = {grammar = {self}, match = lipeg.match_negative_lookahead}
    setmetatable(t, lipeg)
    return t
end

function lipeg:match_pass_captures(input, pos, captures)
    local old_capture_size = captures.size
    local success, new_pos, _ = self.grammar[1]:match(input, pos, captures)
    if(not success) then
        captures.size = old_capture_size
        return false, pos, captures
    end

    pos = new_pos
    local capture_params = {}
    captures.size = captures.size - self.num_captures
    for i = 1, self.num_captures do
        table.insert(capture_params, captures[captures.size + i])
    end

    

    local replacement = self.pass_captures(table.unpack(capture_params))
    captures.size = captures.size + 1
    captures[captures.size] = replacement
    return true, pos, captures
end
        

function lipeg:__div(other)
    assert(type(other) == "function", "Captures can only be passed to a function")
    local t = {grammar = {self}, pass_captures = other, num_captures = debug.getinfo(other).nparams, match = lipeg.match_pass_captures}
    setmetatable(t, lipeg)
    return t
end

function lipeg:match_set(input, pos, captures)

    if(pos > #input) then
        return false, pos, captures
    end
    local ch = string.byte(input, pos)
    if(self.grammar[ch]) then
        return true, pos + 1, captures
    else
        return false, pos, captures
    end
end

function lipeg.S(set)
    local grammar = {}
    for i = 1, #set do
        grammar[string.byte(set, i)] = true
    end
    local t = {grammar = grammar, match = lipeg.match_set}
    setmetatable(t, lipeg)
    return t
end

function lipeg:match_capture(input, pos, captures)
    local old_capture_size = captures.size
    local success, new_pos, _ = self.grammar[1]:match(input, pos, captures)

    if(success) then
        captures.size = captures.size + 1
        captures[captures.size] =  string.sub(input, pos, new_pos - 1)
        return true, new_pos, captures
    else
        captures.size = old_capture_size
        return false, pos, captures
    end
end

function lipeg.C(pattern)
    local t = {grammar = {pattern}, match = lipeg.match_capture}
    setmetatable(t, lipeg)
    return t
end

function lipeg:match_capture_position(input, pos, captures)
    captures.size = captures.size + 1
    captures[captures.size] = pos
    return true, pos, captures
end

function lipeg.Cp()
    local t = {match = lipeg.match_capture_position}
    setmetatable(t, lipeg)
    return t
end

-- match already closely emulates the behaviour of Ct, so this function is simply a wrapper
function lipeg.Ct(pattern)
    local t = {grammar = {pattern}, match = pattern.match}
    setmetatable(t, lipeg)
    return t
end


function lipeg:match_range(input, pos, captures)
    if(pos > #input) then
        return false, pos, captures
    end

    local ch = string.byte(input, pos)
    for _, v in pairs(self.ranges) do
        if(ch >= v.start and ch <= v.high) then
            return true, pos + 1, captures
        end
    end
    return false, pos, captures
end

function lipeg.R(...)
    local args = {...}
    local ranges = {}
    for _, v in pairs(args) do
        table.insert(ranges, {start = string.byte(v, 1), high = string.byte(v, 2)})
    end
    local t = {ranges = ranges, match = lipeg.match_range}
    setmetatable(t, lipeg)
    return t
end

function lipeg:findall()
    error("Find all not implemented")
end

function lipeg:match_literal(input, pos, captures)
    if(self.grammar == 1) then
        if(pos <= #input) then
            return true, pos + 1, captures
        else
            return false, pos, captures
        end
    end

    if(#input - pos + 1 < #self.grammar) then
        return false, pos, captures
    end
    if(input:sub(pos, pos + #self.grammar - 1) == self.grammar) then
        return true, pos + #self.grammar, captures
    else
        return false, pos, captures
    end
end

function lipeg:match_sequence(input, pos, captures)
    local old_capture_size = captures.size
    local new_pos = pos
    for k, v in ipairs(self.grammar) do
        local success, temp_pos, _ = v:match(input, new_pos, captures)
        if(success) then
            new_pos = temp_pos
        else
            captures.size = old_capture_size
            return false, pos, captures
        end
    end
    return true, new_pos, captures
end

function lipeg:match_choice(input, pos, captures)
    local old_capture_size = captures.size
    for _, v in ipairs(self.grammar) do
        local success, new_pos, _ = v:match(input, pos, captures)
        if(success) then
            return true, new_pos, captures
        else
            captures.size = old_capture_size
        end
    end

    captures.size = old_capture_size
    return false, pos, captures
end


function lipeg.P(pattern)
    local t = {grammar = pattern, match = lipeg.match_literal}
    setmetatable(t, lipeg)

    return t
end

lipeg.locale_table = {digit = lipeg.R("09"), alpha = lipeg.S("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"), alnum = lipeg.S("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")}

function lipeg.locale()
    return lipeg.locale_table
end

return lipeg
