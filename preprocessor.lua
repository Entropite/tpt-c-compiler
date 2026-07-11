local Preprocessor = {}

function Preprocessor.preprocess(program)
    local patches = {program}
    local has_updated = true
    while has_updated do
        has_updated = false
        local temp_patches = {}
        for i, excerpt in patches do
            local start, fin, included_file = excerpt:find("^include%s+\"(%a+)\"")
            if(not start == nil) then
                has_updated = true
                local file = io.open(included_file)
                if(file == nil) then
                
                else
                    table.insert(temp_patches, file:read("*all"))
                    file:close()
                end
            end
            

        end
    end
end

return Preprocessor