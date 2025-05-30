local Paths = require("/src/Paths")
local moonshine = require(Paths.Lib.Moonshine)

local DropZone = {}
DropZone.__index = DropZone

-- Class-level properties for drop zone dimensions
DropZone.width = 900
DropZone.height = 300
DropZone.TextOffset = 40

function DropZone:new(x, y)
    local instance = setmetatable({}, DropZone)
    instance.x = x
    instance.y = y
    instance.width = DropZone.width -- Use class-level width
    instance.height = DropZone.height -- Use class-level height
    instance.textY = instance.y - DropZone.TextOffset -- Y position for the text above the drop zone
    instance.isGlowing = false -- Whether the glow effect is active
    --instance.glowEffect = moonshine(moonshine.effects.gaussianblur) -- Initialize the glow effect
    --instance.glowEffect.glow.strength = 30 -- Set the glow strength
    --instance.glowEffect.glow.min_luma = 0.
    instance.promptText = "" -- Initialize prompt text
    return instance
end

function DropZone:setPromptText(text)
    self.promptText = text
end

function DropZone:draw()
    if self.isGlowing then
        -- Apply the glow effect
        --self.glowEffect(function()
            love.graphics.setColor(love.math.colorFromBytes(70, 43, 16, 150))
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
             -- Draw the border
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
       --end)
    else
        -- Draw without the glow effect
        love.graphics.setColor(love.math.colorFromBytes(70, 43, 16, 40))
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
         -- Draw the border
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    end

    -- Draw the prompt text
    if self.promptText and self.promptText ~= "" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.promptText, self.x, self.textY - 10)
    end
end

function DropZone:isInside(x, y, width, height)
    return x + width > self.x and x < self.x + self.width and
           y + height > self.y and y < self.y + self.height
end

function DropZone:setGlowing(isGlowing)
    self.isGlowing = isGlowing
end

return DropZone