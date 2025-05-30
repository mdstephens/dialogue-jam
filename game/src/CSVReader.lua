local CSVReader = {}

local function parseCSVLine(line)
    local result = {}
    local current = ""
    local inQuotes = false
    
    for i = 1, #line do
        local char = line:sub(i, i)
        if char == '"' then
            if inQuotes == true and i < #line and line:sub(i+1, i+1) == '"' then    -- handle escaped quotes
                current = current .. '"'
                i = i + 1
            else                                                                    -- we hit a non-escaped quote
                inQuotes = not inQuotes
            end
        elseif char == ',' and inQuotes == false then                                    -- we hit the end of the field
            table.insert(result, current:match("^%s*(.-)%s*$"))                     -- trim whitespace
            current = ""
        else
            current = current .. char
        end
    end
    
    -- Add the last field
    table.insert(result, current:match("^%s*(.-)%s*$")) -- Trim whitespace
    
    return result
end

function CSVReader.read(filename)
    local data = {}
    local headers = {}
    
    -- Read the entire file content using love.filesystem
    local fileContent = love.filesystem.read(filename)
    if not fileContent then
        error("Could not open file: " .. filename)
    end

    -- Split the file content into lines
    local lines = {}
    for line in fileContent:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Parse the header line
    local headerLine = lines[1]
    if headerLine then
        headers = parseCSVLine(headerLine)
    end

    -- Parse the remaining lines
    for i = 2, #lines do
        local line = lines[i]
        local values = parseCSVLine(line)
        local row = {}
        for j, value in ipairs(values) do
            if j <= #headers then
                row[headers[j]] = value
            else
                print("  WARNING: More values than headers!")
            end
        end    
        table.insert(data, row)
    end

    return data
end

function CSVReader.readDialogue(filename)
    local data = CSVReader.read(filename)
    local dialogue = {}    
    for _, row in ipairs(data) do
        if row["Key"] then
            local responses = {}
            if row["Resp1"] and row["Resp1"] ~= "" then
                responses[row["Resp1"]] = row["Key1"]
            end
            if row["Resp2"] and row["Resp2"] ~= "" then
                responses[row["Resp2"]] = row["Key2"]
            end
            if row["Resp3"] and row["Resp3"] ~= "" then
                responses[row["Resp3"]] = row["Key3"]
            end
            if row["Resp4"] and row["Resp4"] ~= "" then
                responses[row["Resp4"]] = row["Key4"]
            end            
            dialogue[row["Key"]] = {row["Prompt"], responses}
        else
            print("WARNING: Row missing Key field")
        end
    end
    return dialogue
end

return CSVReader