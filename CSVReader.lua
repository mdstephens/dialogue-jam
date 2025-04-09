local CSVReader = {}
CSVReader.__index = CSVReader

function CSVReader:new()
    local instance = setmetatable({}, CSVReader)
    return instance
end

function CSVReader:read(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename)
    end
    
    local data = {}
    local headers = {}
    
    -- Read the first line as headers
    local headerLine = file:read("*l")
    if headerLine then
        for header in headerLine:gmatch("([^,]+)") do
            table.insert(headers, header:match("^%s*(.-)%s*$")) -- Trim whitespace
        end
    end
    
    -- Read the rest of the file
    for line in file:lines() do
        local row = {}
        local i = 1
        for value in line:gmatch("([^,]+)") do
            row[headers[i]] = value:match("^%s*(.-)%s*$") -- Trim whitespace
            i = i + 1
        end
        table.insert(data, row)
    end
    
    file:close()
    return data
end

return CSVReader