local Paths = require("/src/Paths")
local DropZone = require(Paths.SRC.DropZone)
local TextCard = require(Paths.SRC.TextCard)

local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu:new()
    local instance = setmetatable({}, MainMenu)
    instance.cards = {}
    instance.dropZone = nil

    -- Initialize drop zone
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local dropZoneX = (screenWidth - DropZone.width) / 2
    local dropZoneY = screenHeight / 3 - DropZone.height / 2
    instance.dropZone = DropZone:new(dropZoneX, dropZoneY)
    instance.dropZone:setPromptText("Contract") -- Set the prompt text here

    -- Initialize menu cards with a delay
    local cardXOffsets = {screenWidth * 0.3, screenWidth * 0.7}
    local cardY = screenHeight * 0.6

    instance.cardSpawnTimers = {0.4, 0.8} -- Delays for each card in seconds
    instance.cardSpawned = {false, false} -- Track if cards are spawned

    instance.cardData = {
        {x = cardXOffsets[1] - TextCard.width / 2, y = cardY, text = "Play", key = "play"},
        {x = cardXOffsets[2] - TextCard.width / 2, y = cardY, text = "Exit", key = "exit"}
    }

    -- Flag to track if main theme has started
    instance.mainThemeStarted = false

    return instance
end

function MainMenu:update(dt)
    local isAnyCardInside = false

    -- Handle card spawning with delays
    for i, timer in ipairs(self.cardSpawnTimers) do
        if not self.cardSpawned[i] then
            self.cardSpawnTimers[i] = self.cardSpawnTimers[i] - dt
            if self.cardSpawnTimers[i] <= 0 then
                local cardData = self.cardData[i]
                table.insert(self.cards, TextCard:new(cardData.x, cardData.y, cardData.text, cardData.key))
                self.cardSpawned[i] = true
            end
        end
    end

    -- Check if all cards have spawned and play the main theme
    if not self.mainThemeStarted and self:allCardsSpawned() then
        self.mainThemeStarted = true
        local mainTheme = love.audio.newSource(Paths.Audio.MainTheme, "stream")
        mainTheme:setVolume(0.01) -- Adjust volume if needed
        mainTheme:setLooping(true) -- Enable looping
        mainTheme:play()
    end

    for _, card in ipairs(self.cards) do
        card:update(dt)
        if self.dropZone:isInside(card.x, card.y, card.width, card.height) then
            isAnyCardInside = true
            break
        end
    end

    -- Toggle the glow effect based on card overlap
    self.dropZone:setGlowing(isAnyCardInside)
end

function MainMenu:draw()
    -- Draw the drop zone
    self.dropZone:draw()

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

                -- Play the "PlayStarted" audio
                local playStartedSound = love.audio.newSource(Paths.Audio.PlayStarted, "stream")
                playStartedSound:setVolume(0.3) -- Adjust volume if needed
                playStartedSound:play()
                return "play" -- Signal to start the game

            elseif card.key == "exit" then
                print("Exit button used.")
                return "exit" -- Signal to exit
            end
        end
    end
end

function MainMenu:allCardsSpawned()
    for _, spawned in ipairs(self.cardSpawned) do
        if not spawned then
            return false
        end
    end
    return true
end

return MainMenu