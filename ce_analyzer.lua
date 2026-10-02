local utils = require("util")
local Node = require("node")
local Token = require("token")


local ce_analyzer = {}
ce_analyzer.cache = {}
setmetatable(ce_analyzer.cache, {__mode="k"})

ce_analyzer.inverted_status_types = {
    "NONE",
    "ICE",
    "ICE_LIST",
    "ACE",
    "AC",
}

ce_analyzer.status_types = utils.invert_table(ce_analyzer.inverted_status_types)

ce_analyzer.get_status = function(node) 
    if ce_analyzer.cache[node] then
        return ce_analyzer.cache[node].status
    end


    ce_analyzer.cache[node] = dispatch(node)
    return ce_analyzer.cache[node].status
end

ce_analyzer.get_value = function(node)
    if ce_analyzer.cache[node] then
        return ce_analyzer.cache[node].value
    end

    ce_analyzer.cache[node] = dispatch(node)
    return ce_analyzer.cache[node].value
end

ce_analyzer.ce = function(status, value) return {["status"] = ce_analyzer.status_types[status], ["value"] = value} end


-- ce_analyzer.check_initializer = function(node)
--     if(node_check(node, "INITIALIZER_LIST")) then
--         for i = 1, #node do

-- end


function dispatch(node)
    local node_check = Node.node_check
    local ce = ce_analyzer.ce
    local TOKEN_TYPES = Token.TOKEN_TYPES

    function ternary_expression(node)
        if node_check(node, "TERNARY") then

        else
            return logical_or_expression(node)
        end
    end

    function logical_or_expression(node)
        if(node_check(node, "LOGICAL_OR_EXPRESSION")) then

        else
            return logical_and_expression(node)
        end
    end

    function logical_and_expression(node)
        if(node_check(node, "LOGICAL_AND_EXPRESSION")) then

        else
            return inclusive_or_expression(node)
        end
    end

    function inclusive_or_expression(node)
        if(node_check(node, "INCLUSIVE_OR_EXPRESSION")) then

        else
            return inclusive_xor_expression(node)
        end
    end

    function inclusive_xor_expression(node)
        if(node_check(node, "INCLUSIVE_XOR_EXPRESSION")) then

        else
            return inclusive_and_expression(node)
        end
    end

    function inclusive_and_expression(node)
        if(node_check(node, "INCLUSIVE_AND_EXPRESSION")) then

        else
            return equality_expression(node)
        end
    end

    function equality_expression(node)
        if(node_check(node, "EQUALITY_EXPRESSION")) then

        else
            return relational_expression(node)
        end
    end

    function relational_expression(node)
        if(node_check(node, "RELATIONAL_EXPRESSION")) then

        else
            return shift_expression(node)
        end
    end

    function shift_expression(node)
        if(node_check(node, "SHIFT_EXPRESSION")) then
            
        else
            return sum_expression(node)
        end
    end


    function check_status(ce, status)
        return ce.status == ce_analyzer.status_types[status]
    end

    function sum_expression(node)
        if(node_check(node, "SUM_EXPRESSION")) then
            
            local res_ce = multiplicative_expression(node[1])
            if(check_status(res_ce, "NONE")) then
                return res_ce
            end
            for i = 3, #node, 2 do
                local term = node[i]
                local term_ce = multiplicative_expression(term)
                if(term_ce.status == ce_analyzer.status_types["ICE"]) then
                    
                    if(node[i - 1].type == TOKEN_TYPES["+"]) then
                        res_ce.value = res_ce.value + term_ce.value
                    else
                        res_ce.value = res_ce.value - term_ce.value
                    end
                else
                    return term_ce
                end
            end
            return res_ce
        else
            return multiplicative_expression(node)
        end
    end
    
    function multiplicative_expression(node)
        if(node_check(node, "MULTIPLICATIVE_EXPRESSION")) then
            local res_ce = cast_expression(node[1])
            if(check_status(res_ce, "NONE")) then
                return res_ce
            end
            for i = 3, #node, 2 do
                local term = node[i]
                local term_ce = cast_expression(term)
                if(check_status(term_ce, "ICE")) then
                    if(node[i - 1].type == TOKEN_TYPES["*"]) then
                        res_ce.value = res_ce.value * term_ce.value
                    else
                        res_ce.value = res_ce.value / term_ce.value
                    end
                else
                    return term_ce
                end
            end
            return res_ce
        else
            return cast_expression(node)
        end
    end

    function cast_expression(node)
        if(node_check(node, "CAST_EXPRESSION")) then

        else
            return unary_expression(node)
        end
    end
    
    
    function unary_expression(node)
        if(node_check(node, "UNARY_EXPRESSION")) then
            
        else
            return postfix_expression(node)
        end
    end
    
    function postfix_expression(node)
        if(node_check(node, "POSTFIX_EXPRESSION")) then
            
        else
            return primary_expression(node)
        end
    end

    function primary_expression(node)
        if(node_check(node, "INT") or node_check(node, "LONG") or node_check(node, "CHARACTER")) then
            return ce("ICE", node.value)
        elseif(node_check(node, "EXPRESSION")) then
            return ternary_expression(node)
        elseif(node_check(node, "STRING_LITERAL")) then
            return ce("AC", nil)
        else
            print(Node.INVERTED_NODE_TYPES[node.type], node.pos.row)
            return ce("NONE", nil)
        end
    end

    if(node_check(node, "INITIALIZER_LIST")) then
        for i = 1, #node do
            local temp = dispatch(node[i])
            if(not (check_status(temp, "ICE") or check_status(temp, "ICE_LIST"))) then
                return temp
            end
        end
        return ce("ICE_LIST", node)
    elseif(node_check(node, "INITIALIZER")) then
        local temp = dispatch(node.value)
        if(not check_status(temp, "ICE")) then
            return temp
        else
            node.value = Node:new(Node.NODE_TYPES["INT"], node.value.pos)
            node.value.value = temp.value
            return temp
        end
        

    else
        return ternary_expression(node)
    end
end
-- functions are parsed at runtime! Make sure they are statically parsed!
return ce_analyzer