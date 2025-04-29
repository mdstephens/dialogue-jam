local MainMenu = {}
MainMenu.__index = MainMenu

local TextCard = require("TextCard")
local DropZone = require("DropZone")

function MainMenu:new()
    local instance = setmetatable({}, MainMenu)
    instance.cards = {}
    instance.dropZone = nil
    instance.promptText = "Drag a card into the drop zone to select an option."

    -- Initialize drop zone
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local dropZoneX = (screenWidth - DropZone.width) / 2
    local dropZoneY = screenHeight / 3 - DropZone.height / 2
    instance.dropZone = DropZone:new(dropZoneX, dropZoneY)

    -- Initialize menu cards
    local cardXOffsets = {screenWidth * 0.3, screenWidth * 0.7}
    local cardY = screenHeight * 0.6

    table.insert(instance.cards, TextCard:new(cardXOffsets[1] - TextCard.width / 2, cardY, "Play", "play"))
    table.insert(instance.cards, TextCard:new(cardXOffsets[2] - TextCard.width / 2, cardY, "Exit", "exit"))

    return instance
end

function MainMenu:update(dt)
    for _, card in ipairs(self.cards) do
        card:update(dt)
    end
end

function MainMenu:draw()
    -- Draw the drop zone
    self.dropZone:draw()

    -- Draw the prompt text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.promptText, self.dropZone.x, self.dropZone.y - 30)

    -- Draw all cards
    for _, card in ipairs(self.cards) do
        card:draw()
    end
end

function MainMenu:mousepressed(x, y, button)
    for _, card in ipairs(self.cards) do
        card:mousepressed(x, y, button)
    end
end

function MainMenu:mousereleased(x, y, button)
    for i = #self.cards, 1, -1 do
        local card = self.cards[i]
        card:mousereleased(button)

        -- Check if the card is inside the drop zone
        if self.dropZone:isInside(card.x, card.y, card.width, card.height) then
            if card.key == "play" then
                print("Play button used.")
                return "play" -- Signal to start the game
            elseif card.key == "exit" then
                print("Exit button used.")
                return "exit" -- Signal to exit
            end
        end
    end
end

return MainMenu