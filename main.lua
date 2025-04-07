io.stdout:setvbuf('no')

local TextCard = require("TextCard")
local DropZone = require("DropZone")

local cards = {}
local dropZone
local destroyedCardText = ""

function love.load()
    love.graphics.setFont(love.graphics.newFont(14)) -- Set font size for the text

    -- Create the drop zone
    dropZone = DropZone:new(150, 50, 500, 100)

    -- Create 4 cards in the lower half of the screen
    table.insert(cards, TextCard:new(100, 400, 200, 50, "Card 1"))
    table.insert(cards, TextCard:new(350, 400, 200, 50, "Card 2"))
    table.insert(cards, TextCard:new(100, 500, 200, 50, "Card 3"))
    table.insert(cards, TextCard:new(350, 500, 200, 50, "Card 4"))
end

function love.draw()
    -- Draw the drop zone
    dropZone:draw()

    -- Draw the text box above the drop zone
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Destroyed Card: " .. destroyedCardText, dropZone.x, dropZone.y - 30)

    -- Draw all cards
    for _, card in ipairs(cards) do
        card:draw()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    for _, card in ipairs(cards) do
        card:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    for i = #cards, 1, -1 do
        local card = cards[i]
        card:mousereleased(button)

        -- Check if the card is inside the drop zone
        if dropZone:isInside(card.x, card.y, card.width, card.height) then
            destroyedCardText = card.text -- Update the text box with the card's name
            table.remove(cards, i) -- Remove the card from the list
        end
    end
end

function love.update(dt)
    for _, card in ipairs(cards) do
        card:update(dt) -- Pass dt to each card's update method
    end
end