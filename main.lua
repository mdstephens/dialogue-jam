io.stdout:setvbuf('no')

local TextCard = require("TextCard")
local DropZone = require("DropZone")
local CSVReader = require("CSVReader")

local cards = {}
local dropZone
local destroyedCardText = ""
local promptText = ""
local dialogueTree

function love.load()
    love.graphics.setFont(love.graphics.newFont(14)) -- Set font size for the text

    -- Create the drop zone
    dropZone = DropZone:new(150, 50, 500, 100)

    -- Read Dialogue CSV
    dialogueTree = CSVReader.readDialogue("Dialogue.csv")
    local dialogueElem = dialogueTree["1"]
    loadDialogueElem(dialogueElem[1], dialogueElem[2])
end

function clearCards()
    for i = #cards, 1, -1 do
        table.remove(cards, i) -- Remove the card from the list
    end
end

function loadDialogueElem(prompt, responses)
    clearCards()
    promptText = prompt
    local i = 1
    for k, v in pairs(responses) do
        -- Create 4 cards in the lower half of the screen
        if i == 1 then
            table.insert(cards, TextCard:new(100, 400, 200, 50, k, v))
        end
        
        if i == 2 then
            table.insert(cards, TextCard:new(350, 400, 200, 50, k, v))
        end
        
        if i == 3 then
            table.insert(cards, TextCard:new(100, 500, 200, 50, k, v))
        end

        if i == 4 then
            table.insert(cards, TextCard:new(350, 500, 200, 50, k, v))
        end
        i = i + 1
    end
end

function love.draw()
    -- Draw the drop zone
    dropZone:draw()

    -- Draw the text box above the drop zone
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(promptText, dropZone.x, dropZone.y - 30)

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
            if card.key ~= "" then
                print("Took route " .. card.key .. ".")
                destroyedCardText = card.key -- Update the text box with the card's name
                table.remove(cards, i) -- Remove the card from the list
                loadDialogueElem(dialogueTree[card.key][1], dialogueTree[card.key][2])
            else
                print("End of route.")
                clearCards()
            end
        end
    end
end

function love.update(dt)
    for _, card in ipairs(cards) do
        card:update(dt) -- Pass dt to each card's update method
    end
end