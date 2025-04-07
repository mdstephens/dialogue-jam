local DropZone = {}
DropZone.__index = DropZone

function DropZone:new(x, y, width, height)
    local instance = setmetatable({}, DropZone)
    instance.x = x
    instance.y = y
    instance.width = width
    instance.height = height
    return instance
end

function DropZone:draw()
    -- Draw the drop zone rectangle
    love.graphics.setColor(0.8, 0.5, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function DropZone:isInside(x, y, width, height)
    -- Check if a rectangle (e.g., a card) is inside the drop zone
    return x + width > self.x and x < self.x + self.width and
           y + height > self.y and y < self.y + self.height
end

return DropZone