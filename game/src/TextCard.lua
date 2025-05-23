local Paths = require("/src/Paths")

local TextCard = {}
TextCard.__index = TextCard

-- Class-level properties for card dimensions
TextCard.width = 500
TextCard.height = 175


function TextCard:new(x, y, text, key)
    local instance = setmetatable({}, TextCard)
    instance.x = x
    instance.y = y
    instance.lastX = x -- Cache the initial position
    instance.lastY = y -- Cache the initial position
    instance.width = TextCard.width -- Use class-level width
    instance.height = TextCard.height -- Use class-level height
    instance.text = text
    instance.key = key
    instance.isDragging = false
    instance.offsetX = 0
    instance.offsetY = 0
    instance.damping = 0.9 -- Damping factor to reduce velocity over time
    instance.lerpSpeed = 10 -- Speed of interpolation for dragging

    -- Add random drifting velocity
    local driftSpeed = 12 -- Adjust this value for faster or slower drifting
    instance.velocityX = (math.random() * 2 - 1) * driftSpeed
    instance.velocityY = (math.random() * 2 - 1) * driftSpeed

    -- Play the "CardSpawned" audio when the card is created
    local cardSpawnedSound = love.audio.newSource(Paths.Audio.CardSpawned, "static")
    cardSpawnedSound:setVolume(0.5) -- Adjust volume if needed
    cardSpawnedSound:play()

    return instance
end

function TextCard:draw()
    -- Draw the rectangle
    love.graphics.setColor(love.math.colorFromBytes(201, 130, 64, 200))
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(love.math.colorFromBytes(170, 120, 74))
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- Draw the text inside the rectangle with word wrapping and vertical centering
    local padding = 10 -- Add some padding around the text
    local font = love.graphics.getFont()
    local maxWidth = self.width - 2 * padding -- Maximum width for wrapping

    -- Calculate wrapped text and total height
    local _, wrappedText = font:getWrap(self.text, maxWidth)
    local textHeight = #wrappedText * font:getHeight()

    -- Calculate vertical offset to center the text
    local verticalOffset = (self.height - textHeight) / 2

    -- Draw the text outline
    love.graphics.setColor(0, 0, 0) -- Black color for the outline
    for _, offset in ipairs({{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}) do
        love.graphics.printf(
            self.text,
            self.x + padding + offset[1], -- X position with padding and offset
            self.y + verticalOffset + offset[2], -- Y position with vertical centering and offset
            maxWidth,
            "center"
        )
    end

    -- Draw the main text
    love.graphics.setColor(1, 1, 1) -- White color for the main text
    love.graphics.printf(
        self.text,
        self.x + padding,
        self.y + verticalOffset,
        maxWidth,
        "center"
    )
end

function TextCard:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
            self.isDragging = true
            self.offsetX = x - self.x -- Correctly calculate the offset
            self.offsetY = y - self.y -- Correctly calculate the offset
        end
    end
end

function TextCard:mousereleased(button)
    if button == 1 then -- Left mouse button
        self.isDragging = false
        -- Save the last position when dragging stops
        self.lastX = self.x
        self.lastY = self.y
    end
end

function TextCard:update(dt)
    if self.isDragging then
        -- Get the current mouse position
        local mouseX, mouseY = love.mouse.getPosition()

        -- Calculate the target position using the offset
        local targetX = mouseX - self.offsetX
        local targetY = mouseY - self.offsetY

        -- Interpolate the card's position toward the target position
        self.x = self.x + (targetX - self.x) * self.lerpSpeed * dt
        self.y = self.y + (targetY - self.y) * self.lerpSpeed * dt
    else
        -- Drift the card based on its velocity
        self.x = self.x + self.velocityX * dt
        self.y = self.y + self.velocityY * dt

        -- Keep the card at its last saved position
        self.lastX = self.x
        self.lastY = self.y
    end
end

function TextCard:isInsideDropZone(dropZone)
    return self.x + self.width > dropZone.x and self.x < dropZone.x + dropZone.width and
           self.y + self.height > dropZone.y and self.y < dropZone.y + dropZone.height
end

return TextCard