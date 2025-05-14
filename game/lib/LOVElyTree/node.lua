local RESULT = require("LOVElyTree.result")

---@class LOVElyTree.Node
---@field status LOVElyTree.Result
---@field children LOVElyTree.Node[]?
---@field current number
---@field child LOVElyTree.Node?
local Node = {}
Node.__index = Node

function Node.new()
  local obj = { status = RESULT.IDLE, node_type = "Node" }
  setmetatable(obj, Node)
  return obj
end

---Updates the node
---@param dt number Time since last update
---@param blackboard LOVElyTree.Blackboard?
---@return LOVElyTree.Result
function Node:update(dt, blackboard)
  return self.status
end

function Node:reset()
  self.status = RESULT.IDLE
end

return Node.new
