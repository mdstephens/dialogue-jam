local module = (...):match("(.-)[^%.]+$")
local tree_render = require(module .. "tree_render")
local RESULT = require(module .. "result")

---@class LOVElyTree.BehaviorTree
---@field root LOVElyTree.Node
---@field status LOVElyTree.Result
---@field blackboard LOVElyTree.Blackboard?
local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

---@alias LOVElyTree.Blackboard table

---@param root LOVElyTree.Node
---@param blackboard LOVElyTree.Blackboard?
---@return LOVElyTree.BehaviorTree
function BehaviorTree.new(root, blackboard)
  local obj = { root = root, blackboard = blackboard }
  setmetatable(obj, BehaviorTree)
  return obj
end

function BehaviorTree:update(dt)
  self.root:update(dt, self.blackboard)
  if self.root.status ~= RESULT.RUNNING then
    self:reset()
  end
end

function BehaviorTree:reset()
  self.root:reset()
end

return BehaviorTree.new