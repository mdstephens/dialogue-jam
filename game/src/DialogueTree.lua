local Node = require("LOVElyTree/node")
local CSVReader = require("CSVReader")

local DialogueTree = {}

--- Creates a dialogue node, extending the base LOVElyTree.Node
---@param key string | number
---@param prompt string
---@param responses table<string, string> @ Map of response text to the next node's key
---@return LOVElyTree.Node
local function createDialogueNode(key, prompt, responses)
    local node = Node() -- Create a base node
    node.key = key
    node.prompt = prompt
    node.responses = responses -- Initially stores {responseText = nextKey}
    node.node_type = "DialogueNode" -- Differentiate from generic nodes
    node.childrenByKey = {} -- Will store {responseText = childNode} after linking
    node.children = {} -- Add the standard children array for the renderer
    return node
end

--- Loads dialogue data from a CSV file and builds a tree of Node objects.
---@param filename string The path to the CSV file.
---@return table<string, LOVElyTree.Node>?, LOVElyTree.Node? @ Returns a table of all nodes indexed by key, and the root node (key "1")
function DialogueTree.load(filename)
    local dialogueData = CSVReader.readDialogue(filename)
    if not dialogueData then
        print("Error: Could not read dialogue data from " .. filename)
        return nil
    end

    local nodes = {}

    -- First pass: Create all node objects
    for key, data in pairs(dialogueData) do
        local prompt = data[1]
        local responses = data[2]
        nodes[tostring(key)] = createDialogueNode(key, prompt, responses)
    end

    -- Second pass: Link nodes together
    for key, node in pairs(nodes) do
        if node.responses then
            for responseText, nextKey in pairs(node.responses) do
                local nextNode = nodes[tostring(nextKey)]
                if nextNode then
                    node.childrenByKey[responseText] = nextNode
                    table.insert(node.children, nextNode) -- Add to the children array as well
                else
                    print("Warning: Could not find node for key '" .. tostring(nextKey) .. "' referenced by node '" .. tostring(key) .. "' response '" .. responseText .. "'")
                end
            end
        end
        -- We might not need the original responses table anymore after linking
        -- node.responses = nil 
    end

    local rootNode = nodes["1"]
    if not rootNode then
        print("Warning: Could not find root node with key '1'")
    end

    return nodes, rootNode
end

return DialogueTree