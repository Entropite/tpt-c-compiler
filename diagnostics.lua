local Message = require("message")

local Diagnostics = {messages = {}, tolerance = Message.TYPES["ERROR"]}


function Diagnostics.submit(message)
    if(message.type >= Diagnostics.tolerance) then
        Diagnostics.on_panic(message)
    else
        table.insert(Diagnostics.messages, message)
    end
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