local Message = require("message")

local Diagnostics = {messages = {}, tolerance = Message.TYPES["ERROR"]}


function Diagnostics.submit(message)
    if(message.type >= Diagnostics.tolerance) then
        Diagnostics.on_panic(message)
    else
        table.insert(Diagnostics.messages, message)
    end
end

Diagnostics.node_tallies = {}
function Diagnostics.ast_size(ast)
    local count = 1
    Diagnostics.node_tallies[ast.type] = (Diagnostics.node_tallies[ast.type] or 0) + 1
    for _, child in pairs(ast) do
        if(type(child) == "table" and child.is_node) then
            count = count + Diagnostics.ast_size(child)
        end
    end
    return count
end

function Diagnostics.default_on_panic(message, pos)
    print(message)
    Diagnostics.recover()
end

function Diagnostics.default_recover()
    os.exit(1)
end

Diagnostics.on_panic = Diagnostics.default_on_panic
Diagnostics.recover = Diagnostics.default_recover

return Diagnostics