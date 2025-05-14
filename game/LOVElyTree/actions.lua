local module = (...):match("(.-)[^%.]+$")
local Node = require(module .. "node")
local RESULT = require(module .. "result")

---@class LOVElyTree.Actions.Wait : LOVElyTree.Node
local Wait = {}
Wait.__index = Wait

---@param wait_time number Time to wait in seconds
---@return LOVElyTree.Actions.Wait
function Wait.new(wait_time)
  local obj = Node()
  setmetatable(obj, Wait)
  obj.wait_time = wait_time
  obj.timer = 0
  obj.node_type = "ActionWait"
  return obj
end

function Wait:update(dt, blackboard)
  if self.timer < self.wait_time then
    self.timer = self.timer + dt
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.SUCCESS
  end
  return self.status
end

function Wait:reset()
  self.timer = 0
  self.status = RESULT.IDLE
end

---@class LOVElyTree.Actions.RandomWait : LOVElyTree.Node
local RandomWait = {}
RandomWait.__index = RandomWait

---@param min_time number Minimum time to wait in seconds
---@param max_time number Maximum time to wait in seconds
---@return LOVElyTree.Actions.RandomWait
function RandomWait.new(min_time, max_time)
  local obj = Node()
  setmetatable(obj, RandomWait)
  obj.min_time = min_time
  obj.max_time = max_time
  obj.wait_time = math.random() * (max_time - min_time) + min_time
  obj.timer = 0
  obj.node_type = "ActionRandomWait"
  return obj
end

function RandomWait:update(dt, blackboard)
  if self.timer < self.wait_time then
    self.timer = self.timer + dt
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.SUCCESS
  end
  return self.status
end

function RandomWait:reset()
  self.timer = 0
  self.wait_time = math.random() * (self.max_time - self.min_time) + self.min_time
  self.status = RESULT.IDLE
end

---@class LOVElyTree.Actions.SetBlackboard : LOVElyTree.Node
local SetBlackboard = {}
SetBlackboard.__index = SetBlackboard

---@param key string
---@param value any
---@return LOVElyTree.Actions.SetBlackboard
function SetBlackboard.new(key, value)
  local obj = Node()
  setmetatable(obj, SetBlackboard)
  obj.key = key
  obj.value = value
  obj.node_type = "ActionSetBlackboard"
  return obj
end

function SetBlackboard:update(dt, blackboard)
  blackboard[self.key] = self.value
  self.status = RESULT.SUCCESS
  return self.status
end

function SetBlackboard:reset()
  self.status = RESULT.IDLE
end

---@class LOVElyTree.Actions.CheckBlackboard : LOVElyTree.Node
---@field key string
---@field expected any
local CheckBlackboard = {}
CheckBlackboard.__index = CheckBlackboard

---@param key string
---@param expected any
---@return LOVElyTree.Actions.CheckBlackboard
function CheckBlackboard.new(key, expected)
  local obj = Node()
  setmetatable(obj, CheckBlackboard)
  obj.key = key
  obj.expected = expected
  obj.node_type = "ActionCheckBlackboard"
  return obj
end

function CheckBlackboard:update(dt, blackboard)
  if blackboard[self.key] == self.expected then
    self.status = RESULT.SUCCESS
  else
    self.status = RESULT.FAILURE
  end
  return self.status
end

function CheckBlackboard:reset()
  self.status = RESULT.IDLE
end

local Actions = {
  Wait = Wait.new,
  RandomWait = RandomWait.new,
  SetBlackboard = SetBlackboard.new,
  CheckBlackboard = CheckBlackboard.new,
}

return Actions
