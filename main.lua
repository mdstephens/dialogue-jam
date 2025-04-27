io.stdout:setvbuf('no')

local TextCard = require("TextCard")
local DropZone = require("DropZone")
local CSVReader = require("CSVReader")
local moonshine = require 'moonshine'

local cards = {}
local dropZone
local destroyedCardText = ""
local promptText = ""
local dialogueTree
local starfieldShader

function love.load()
    -- Set font size for the text
    local font = love.graphics.newFont("x14y24pxHeadUpDaisy.ttf", 28) -- Thanks @hicchicc for the font
    love.graphics.setFont(font) -- Set the font as the active font

    -- Set moonshine shaders
    effect = moonshine(moonshine.effects.scanlines).chain(
                        moonshine.effects.crt).chain(
                        moonshine.effects.glow).chain(
                        moonshine.effects.chromasep)
    effect.crt.distortionFactor = {1.05, 1.06}
    effect.scanlines.opacity = 0.6
    effect.glow.strength = 15
    effect.glow.min_luma = 0.2

    -- Load the starfield shader
    starfieldShader = love.graphics.newShader("starfield.glsl")

    -- Send resolution to the shader
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    starfieldShader:send("resolution", {screenWidth, screenHeight})

    -- Calculate dynamic position for the drop zone
    local dropZoneWidth = 900
    local dropZoneHeight = 300
    local dropZoneX = (screenWidth - dropZoneWidth) / 2
    local dropZoneY = screenHeight / 3 - dropZoneHeight / 2

    -- Create the drop zone
    dropZone = DropZone:new(dropZoneX, dropZoneY, dropZoneWidth, dropZoneHeight)

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
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Define card dimensions
    local cardWidth = 500
    local cardHeight = 175

    -- Calculate positions dynamically
    local cardXOffsets = {screenWidth * 0.3, screenWidth * 0.7, screenWidth * 0.3, screenWidth * 0.7}
    local cardYOffsets = {screenHeight * 0.6, screenHeight * 0.6, screenHeight * 0.8, screenHeight * 0.8}

    local i = 1
    for k, v in pairs(responses) do
        if i <= 4 then
            table.insert(cards, TextCard:new(cardXOffsets[i] - cardWidth / 2, cardYOffsets[i] - cardHeight / 2, cardWidth, cardHeight, k, v))
        end
        i = i + 1
    end
end

function love.draw()


    -- Apply moonshine effects and draw other elements
    effect(function()

        -- Apply the starfield shader
        love.graphics.setShader(starfieldShader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader() -- Reset the shader


        -- Draw the drop zone
        dropZone:draw()

        -- Draw the text box above the drop zone
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(promptText, dropZone.x, dropZone.y - 30)

        -- Draw all cards
        for _, card in ipairs(cards) do
            card:draw()
        end
    end)
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
    -- Update time for the shader
    if starfieldShader then
        starfieldShader:send("time", love.timer.getTime()) -- Pass the current time to the shader
    end

    -- Update all cards
    for _, card in ipairs(cards) do
        card:update(dt) -- Pass dt to each card's update method
    end
end