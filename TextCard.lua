local TextCard = {}
TextCard.__index = TextCard

-- Class-level properties for card dimensions
TextCard.width = 500
TextCard.height = 175

function TextCard:new(x, y, text, key)
    local instance = setmetatable({}, TextCard)
    instance.x = x
    instance.y = y
    instance.width = TextCard.width -- Use class-level width
    instance.height = TextCard.height -- Use class-level height
    instance.text = text
    instance.key = key
    instance.isDragging = false
    instance.offsetX = 0
    instance.offsetY = 0
    instance.vx = 0 -- Velocity in the x direction
    instance.vy = 0 -- Velocity in the y direction
    instance.ax = 0 -- Acceleration in the x direction
    instance.ay = 0 -- Acceleration in the y direction
    instance.damping = 0.9 -- Damping factor to reduce velocity over time
    instance.springStrength = 9 -- Spring strength for the jiggle effect
    return instance
end

function TextCard:draw()
    -- Draw the rectangle
    love.graphics.setColor(love.math.colorFromBytes(201, 130, 64, 200))
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(love.math.colorFromBytes(170, 120, 74))
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- Draw the text inside the rectangle with word wrapping and vertical centering
    love.graphics.setColor(1, 1, 1)
    local padding = 10 -- Add some padding around the text
    local font = love.graphics.getFont()
    local maxWidth = self.width - 2 * padding -- Maximum width for wrapping

    -- Calculate wrapped text and total height
    local _, wrappedText = font:getWrap(self.text, maxWidth)
    local textHeight = #wrappedText * font:getHeight()

    -- Calculate vertical offset to center the text
    local verticalOffset = (self.height - textHeight) / 2

    -- Draw the wrapped text
    love.graphics.printf(
        self.text, -- The text to draw
        self.x + padding, -- X position with padding
        self.y + verticalOffset, -- Y position with vertical centering
        maxWidth, -- Maximum width for wrapping
        "center" -- Align the text to the center
    )
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