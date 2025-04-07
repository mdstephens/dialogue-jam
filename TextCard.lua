local TextCard = {}
TextCard.__index = TextCard

function TextCard:new(x, y, width, height, text)
    local instance = setmetatable({}, TextCard)
    instance.x = x
    instance.y = y
    instance.width = width
    instance.height = height
    instance.text = text
    instance.isDragging = false
    instance.offsetX = 0
    instance.offsetY = 0
    instance.vx = 0 -- Velocity in the x direction
    instance.vy = 0 -- Velocity in the y direction
    instance.ax = 0 -- Acceleration in the x direction
    instance.ay = 0 -- Acceleration in the y direction
    instance.damping = .9 -- Damping factor to reduce velocity over time
    instance.springStrength = 9 -- Spring strength for the jiggle effect
    return instance
end

function TextCard:draw()
    -- Draw the rectangle
    love.graphics.setColor(0.5, 0.5, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Draw the text inside the rectangle
    love.graphics.setColor(1, 1, 1)
    local textWidth = love.graphics.getFont():getWidth(self.text)
    local textHeight = love.graphics.getFont():getHeight()
    love.graphics.print(self.text, self.x + (self.width - textWidth) / 2, self.y + (self.height - textHeight) / 2)
end

function TextCard:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
            self.isDragging = true
            self.offsetX = x - self.x
            self.offsetY = y - self.y
        end
    end
end

function TextCard:mousereleased(button)
    if button == 1 then -- Left mouse button
        self.isDragging = false
    end
end

function TextCard:update(dt)
    if self.isDragging then
        -- Get the current mouse position
        local mouseX, mouseY = love.mouse.getPosition()

        -- Calculate the spring force to make the card follow the mouse
        local targetX = mouseX - self.offsetX
        local targetY = mouseY - self.offsetY
        self.ax = (targetX - self.x) * self.springStrength
        self.ay = (targetY - self.y) * self.springStrength

        -- Clamp acceleration to prevent extreme values
        local maxAcceleration = 2000
        self.ax = math.min(math.max(self.ax, -maxAcceleration), maxAcceleration)
        self.ay = math.min(math.max(self.ay, -maxAcceleration), maxAcceleration)

        -- Update velocity based on acceleration
        self.vx = self.vx + self.ax * dt
        self.vy = self.vy + self.ay * dt
    else
        -- Apply damping to slow down the card when not dragging
        self.vx = self.vx * self.damping
        self.vy = self.vy * self.damping
    end

    -- Clamp velocity to prevent extreme values
    local maxVelocity = 500
    self.vx = math.min(math.max(self.vx, -maxVelocity), maxVelocity)
    self.vy = math.min(math.max(self.vy, -maxVelocity), maxVelocity)

    -- Update position based on velocity
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function TextCard:isInsideDropZone(dropZone)
    return self.x + self.width > dropZone.x and self.x < dropZone.x + dropZone.width and
           self.y + self.height > dropZone.y and self.y < dropZone.y + dropZone.height
end

return TextCard