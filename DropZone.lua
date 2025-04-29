local DropZone = {}
DropZone.__index = DropZone

-- Class-level properties for drop zone dimensions
DropZone.width = 900
DropZone.height = 300

function DropZone:new(x, y)
    local instance = setmetatable({}, DropZone)
    instance.x = x
    instance.y = y
    instance.width = DropZone.width -- Use class-level width
    instance.height = DropZone.height -- Use class-level height
    return instance
end

function DropZone:draw()
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

function DropZone:isInside(x, y, width, height)
    return x + width > self.x and x < self.x + self.width and
           y + height > self.y and y < self.y + self.height
end

return DropZone