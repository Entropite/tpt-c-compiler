local util = require("util")

local lpeg_installed, lpeg = pcall(function() return require("lpeg") end)
lpeg_installed = false
if(not lpeg_installed) then
    lpeg = require("lipeg")
end

local Preprocessor = {}
local locale = lpeg.locale()
Preprocessor.include_pattern = lpeg.Ct(((lpeg.Cp() * lpeg.P("\n")^-1 * lpeg.P("#include") * lpeg.P(" ")^0 * lpeg.C((lpeg.P("\"") + "<") * (locale.alnum + lpeg.S("._-[]|()!@#$%^&*,"))^0 * (lpeg.P("\"") + ">")) * lpeg.Cp() / function(start, filename, finish) return {start=start, finish=finish - 1, value=filename} end) + lpeg.P(1))^0)
    


function Preprocessor.preprocess(program)
    local patch_list = {}

    local visited = {}


    local function process_patch(patch)
        local succ, pos, captures
            if(lpeg_installed) then
                captures = lpeg.match(Preprocessor.include_pattern, patch)
            else
                succ, pos, captures = Preprocessor.include_pattern:match(patch, 1, {size=0})
                util.resize_list(captures, captures.size)
            end
        
        local last_code_patch_pos = 0

        for _, capture in ipairs(captures) do
            local start, finish, name = capture.start, capture.finish, capture.value
            
            -- the include directive must be at the start of a line (must check for either the start of the patch or just after a newline)
            if(start == 1 or patch:sub(start, start) == "\n") then
                name = string.sub(name, 2, #name - 1)

                local segment = string.sub(patch, last_code_patch_pos + 1, start - 1)
                table.insert(patch_list, segment)
                last_code_patch_pos = finish

                if(visited[name] == nil) then
                    visited[name] = true
                    local file = io.open(name)
                    if(file == nil) then
                        error("File " .. name .. " not found")
                    else
                        local content = file:read("*all")
                        file:close()
                        process_patch(content)
                    end
                end
            end
        end

        table.insert(patch_list, string.sub(patch, last_code_patch_pos + 1))
    
    end

    process_patch(program)
    return table.concat(patch_list)
    
end

return Preprocessor