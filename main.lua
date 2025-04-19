io.stdout:setvbuf('no')

local TextCard = require("TextCard")
local DropZone = require("DropZone")
local CSVReader = require("CSVReader")
local DialogueTree = require("DialogueTree")
local TreeRenderer = require("LOVElyTree.tree_render") -- Require the renderer

local cards = {}
local dropZone
local destroyedCardText = ""
local current
local rootNode -- Store the root node for rendering
local showDialogueTree = false -- State variable to control tree display

function love.load()
    love.graphics.setFont(love.graphics.newFont(14)) -- Set font size for the text

    -- Create the drop zone
    dropZone = DropZone:new(150, 50, 500, 100)

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
    clearCards()
    current = node
    local i = 1
    for k, v in pairs(node.responses) do
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
    if showDialogueTree then
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
    else
        -- Draw the normal dialogue interface
        if dropZone then dropZone:draw() end -- Add check if dropZone exists
    end
    -- Draw the text box above the drop zone
    -- Draw the text box above the drop zone
    love.graphics.setColor(1, 1, 1)
    if current and dropZone then -- Check if current node and dropZone exist
         love.graphics.print(current.prompt or "...", dropZone.x, dropZone.y - 30)
    elseif dropZone then
         love.graphics.print("Loading...", dropZone.x, dropZone.y - 30)
    end

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
                local nextNode = current.childrenByKey[card.text] -- Use card.text for lookup
                if nextNode then
                    loadDialogueNode(nextNode)
                else
                    print("Warning: No node found for response: " .. card.text)
                    -- Decide what to do here - maybe stay on the current node or end dialogue?
                    -- For now, let's just clear cards as if it's an end route
                    print("End of route (no next node).")
                    clearCards()
                    showDialogueTree = true -- Show tree when dialogue ends here
                end
            elseif card.key == "" then -- Explicitly check for empty key indicating end route
                print("End of route.")
                clearCards()
                showDialogueTree = true -- Show tree when dialogue ends here
            end
        end
    end
end

function love.update(dt)
    for _, card in ipairs(cards) do
        card:update(dt) -- Pass dt to each card's update method
    end
end