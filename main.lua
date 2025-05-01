io.stdout:setvbuf('no')

local MainMenu = require("MainMenu")
local TextCard = require("TextCard")
local DropZone = require("DropZone")
local CSVReader = require("CSVReader")
local moonshine = require 'moonshine'
local DialogueTree = require("DialogueTree")
local TreeRenderer = require("LOVElyTree.tree_render") -- Require the renderer

local cards = {}
local dropZone
local starfieldShader
local currentState = "menu" -- Start at the menu
local mainMenu
local rootNode
local currentNode
local spawnTimer = 0
local spawnIndex = 1
local responses = {} -- Define responses table
local verification

function love.load()
    -- Set font size for the text
    local font = love.graphics.newFont("x14y24pxHeadUpDaisy.ttf", 36) -- Thanks @hicchicc for the font
    love.graphics.setFont(font) -- Set the font as the active font

    -- Set moonshine shaders
    effect = moonshine(
                        moonshine.effects.pixelate).chain(
                        moonshine.effects.glow).chain(
                        moonshine.effects.chromasep).chain(
                        moonshine.effects.scanlines).chain(
                        moonshine.effects.crt)
    effect.pixelate.size = {1.1,1.1}
    effect.crt.distortionFactor = {1.05, 1.06}
    effect.scanlines.opacity = 0.4
    effect.glow.strength = 10
    effect.glow.min_luma = 0.2

    -- Load the starfield shader
    starfieldShader = love.graphics.newShader("starfield.glsl")

    -- Send resolution to the shader
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    starfieldShader:send("resolution", {screenWidth, screenHeight})

    -- Initialize the main menu
    mainMenu = MainMenu:new()

    -- Calculate dynamic position for the drop zone
    local dropZoneX = (screenWidth - DropZone.width) / 2
    local dropZoneY = screenHeight / 3 - DropZone.height / 2

    -- Create the drop zone
    dropZone = DropZone:new(dropZoneX, dropZoneY)

    -- Store the root node (we don't need allNodes for rendering with TreeRenderer)
    local _, loadedRoot = DialogueTree.load("Dialogue.csv")
    rootNode = loadedRoot -- Assign to the variable accessible by love.draw
    if rootNode then
        loadDialogueNode(rootNode)
    else
        print("ERROR: Could not load root node from Dialogue.csv")
        -- Handle error appropriately, maybe show an error message
    end
end

function clearCards()
    for i = #cards, 1, -1 do
        table.remove(cards, i) -- Remove the card from the list
    end
end

function loadDialogueNode(node)
    node.status = 1
    clearCards()
    dropZone:setPromptText(node.prompt) -- Set the prompt text on the drop zone
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Calculate positions dynamically
    local cardXOffsets = {screenWidth * 0.3, screenWidth * 0.7, screenWidth * 0.3, screenWidth * 0.7}
    local cardYOffsets = {screenHeight * 0.6, screenHeight * 0.6, screenHeight * 0.8, screenHeight * 0.8}

    -- Store responses and positions for delayed spawning
    responses = {}
    for k, v in pairs(node.responses) do
        table.insert(responses, {text = k, key = v})
    end

    spawnTimer = 0
    spawnIndex = 2 -- Start at 2 because the first card will be spawned immediately

    -- Spawn the first card immediately
    if #responses > 0 then
        local firstResponse = responses[1]
        local x = cardXOffsets[1] - TextCard.width / 2
        local y = cardYOffsets[1] - TextCard.height / 2
        table.insert(cards, TextCard:new(x, y, firstResponse.text, firstResponse.key))

    end

    -- Function to spawn remaining cards with delay
    function spawnNextCard()
        if spawnIndex <= #responses then
            local response = responses[spawnIndex]
            local x = cardXOffsets[spawnIndex] - TextCard.width / 2
            local y = cardYOffsets[spawnIndex] - TextCard.height / 2
            table.insert(cards, TextCard:new(x, y, response.text, response.key))
            spawnIndex = spawnIndex + 1
        end
    end
    currentNode = node
end

function love.update(dt)
    -- Update time for the shader
    if starfieldShader then
        starfieldShader:send("time", love.timer.getTime()) -- Pass the current time to the shader
    end

    if currentState == "menu" then
        mainMenu:update(dt)
    elseif currentState == "game" then
        -- Spawn cards with a delay
        if spawnIndex <= #responses then -- Use the correct responses table
            spawnTimer = spawnTimer + dt
            if spawnTimer >= 0.5 then -- 0.5-second delay
                spawnTimer = 0
                spawnNextCard()
            end
        end

        -- Update all cards
        local isAnyCardInside = false
        for _, card in ipairs(cards) do
            card:update(dt)
            if dropZone:isInside(card.x, card.y, card.width, card.height) then
                isAnyCardInside = true
                break
            end
        end
        -- Toggle the glow effect based on card overlap
        dropZone:setGlowing(isAnyCardInside)
    end
end

-- Helper function to calculate the bounds of the tree layout
local function getLayoutBounds(layoutData)
    local maxX = 0
    local maxY = 0

    local function traverse(data)
        if not data then return end
        -- Use BOX_HEIGHT from tree_render (or approximate it)
        local boxHeight = 40 -- Assuming default BOX_HEIGHT
        maxX = math.max(maxX, data.x + data.width)
        maxY = math.max(maxY, data.y + boxHeight)
        if data.children then
            for _, childData in ipairs(data.children) do
                traverse(childData)
            end
        end
    end

    traverse(layoutData)
    return maxX, maxY
end

function love.draw()
    -- Apply moonshine effects and draw other elements
    effect(function()
        -- Apply the starfield shader
        love.graphics.setShader(starfieldShader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader() -- Reset the shader

        if currentState == "menu" then
            mainMenu:draw()
        elseif currentState == "game" then
            -- Draw the drop zone
            dropZone:draw()

            -- Draw all cards
            for _, card in ipairs(cards) do
                card:draw()
            end
        elseif currentState == "tree" then
            if rootNode then
                -- 1. Get layout data
                local layoutData = TreeRenderer.layout_tree(rootNode, 0, 0)

                -- 2. Calculate tree bounds
                local treeWidth, treeHeight = getLayoutBounds(layoutData)

                -- 3. Get window dimensions
                local windowWidth, windowHeight = love.graphics.getDimensions()

                -- 4. Calculate scale factor (with padding)
                local padding = 40 -- pixels padding on each side
                local availableWidth = windowWidth - padding
                local availableHeight = windowHeight - padding

                local scaleX = availableWidth / treeWidth
                local scaleY = availableHeight / treeHeight
                local scale = math.min(scaleX, scaleY, 1.0) -- Don't scale up if tree is small

                 -- 5. Calculate offsets for centering (optional)
                local scaledTreeWidth = treeWidth * scale
                local scaledTreeHeight = treeHeight * scale
                local offsetX = (windowWidth - scaledTreeWidth) / 2
                local offsetY = (windowHeight - scaledTreeHeight) / 2


                -- 6. Apply transformations and render
                love.graphics.push()
                love.graphics.translate(offsetX, offsetY) -- Center the tree
                love.graphics.scale(scale, scale)         -- Apply scaling
                TreeRenderer.render_tree(layoutData)      -- Render using the pre-calculated layout
                love.graphics.pop()
            else
                love.graphics.print("Error: Cannot display tree - root node not loaded.", 10, 10)
            end
        end
    end)
end

function love.mousepressed(x, y, button, istouch, presses)
    if currentState == "menu" then
        mainMenu:mousepressed(x, y, button)
    elseif currentState == "game" then
        for _, card in ipairs(cards) do
            card:mousepressed(x, y, button)
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    print(currentState)
    if currentState == "menu" then
        local action = mainMenu:mousereleased(x, y, button)
        if action == "play" then
            currentState = "game" -- Transition to the game
        elseif action == "exit" then
            print("Exiting game...")
            love.event.quit() -- Exit the game
        end
    elseif currentState == "game" then
        for i = #cards, 1, -1 do
            local card = cards[i]
            card:mousereleased(button)

            -- Check if the card is inside the drop zone
            if dropZone:isInside(card.x, card.y, card.width, card.height) then
                if card.key ~= "" then
                    print("Took route " .. card.key .. ".")
                    table.remove(cards, i) -- Remove the card from the list
                    local nextNode = currentNode.childrenByKey[card.text] -- Use card.text for lookup
                    if nextNode then
                        loadDialogueNode(nextNode)
                        break
                    else
                        print("Warning: No node found for response: " .. card.text)
                        -- Decide what to do here - maybe stay on the current node or end dialogue?
                        -- For now, let's just clear cards as if it's an end route
                        print("End of route (no next node).")
                        clearCards()
                        currentState = "tree" -- Show tree when dialogue ends here
                        break
                    end
                else
                    verification = card.text
                    print("End of route. Verification is: " .. verification)
                    clearCards()
                    currentState = "tree"
                end
            end
        end
    end
end