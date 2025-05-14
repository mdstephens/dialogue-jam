local module = (...):match("(.-)[^%.]+$")
local Node = require(module .. "node")
local RESULT = require(module .. "result")

--- Executes a node a number of times. If the child fails, the counter is reset.
--- When the counter reaches the specified number of times, the node succeeds.
---@class LOVElyTree.Decorators.Repeat : LOVElyTree.Node
---@field child LOVElyTree.Node
---@field package times number The number of times the child should be repeated
---@field package count number The number of times the child has been repeated
local Repeat = {}
Repeat.__index = Repeat

---@param child LOVElyTree.Node
---@param times? number
---@return LOVElyTree.Decorators.Repeat
function Repeat.new(child, times)
  local obj = Node()
  setmetatable(obj, Repeat)
  obj.child = child
  obj.times = times or 0
  obj.node_type = "Repeat"
  obj:reset()
  return obj
end

function Repeat:update(dt, blackboard)
  assert(self.times > 0, "Repeat times must be greater than 0")
  assert(self.count <= self.times, "Repeat count must be less than times")

  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.FAILURE then
    self.count = 0
    self.status = RESULT.FAILURE
  elseif stat == RESULT.RUNNING then
    self.status = RESULT.RUNNING
    return self.status
  else
    self.count = self.count + 1
    self.child:reset()
    self.status = RESULT.RUNNING
  end

  if self.count == self.times then
    self.status = RESULT.SUCCESS
    return self.status
  end

  return self.status
end

function Repeat:reset()
  self.count = 0
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Inverts the result of its child node: SUCCESS becomes FAILURE and vice versa. Running remains the same.
---@class LOVElyTree.Decorators.Invert : LOVElyTree.Node
local Invert = {}
Invert.__index = Invert

---@param child LOVElyTree.Node
---@return LOVElyTree.Decorators.Invert
function Invert.new(child)
  local obj = Node()
  setmetatable(obj, Invert)
  obj.child = child
  obj.node_type = "Invert"
  obj:reset()
  return obj
end

function Invert:update(dt, blackboard)
  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.RUNNING then
    self.status = RESULT.RUNNING
  elseif stat == RESULT.SUCCESS then
    self.status = RESULT.FAILURE
  elseif stat == RESULT.FAILURE then
    self.status = RESULT.SUCCESS
  end
  return self.status
end

function Invert:reset()
  self.status = RESULT.IDLE
  self.child:reset()
end

--- It will run the child node once each update until it returns SUCESS or until attempt limit is reached.
---@class LOVElyTree.Decorators.Retry : LOVElyTree.Node
local Retry = {}
Retry.__index = Retry
function Retry.new(child, attempts)
  local obj = Node()
  setmetatable(obj, Retry)
  obj.child = child
  obj.attempts = attempts or 1
  obj.node_type = "Retry"
  obj:reset()
  return obj
end

function Retry:update(dt, blackboard)
  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.RUNNING then
    self.status = RESULT.RUNNING
  elseif stat == RESULT.SUCCESS then
    self.status = RESULT.SUCCESS
  elseif stat == RESULT.FAILURE then
    self.count = self.count + 1
    if self.count < self.attempts then
      self.child:reset()
      self.status = RESULT.RUNNING
    else
      self.status = RESULT.FAILURE
    end
  end
  return self.status
end

function Retry:reset()
  self.count = 0
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Forces the result of its child to be SUCCESS (unless running).
---@class LOVElyTree.Decorators.AlwaysSuccess : LOVElyTree.Node
local AlwaysSuccess = {}
AlwaysSuccess.__index = AlwaysSuccess
function AlwaysSuccess.new(child)
  local obj = Node()
  setmetatable(obj, AlwaysSuccess)
  obj.child = child
  obj.node_type = "AlwaysSuccess"
  obj:reset()
  return obj
end

function AlwaysSuccess:update(dt, blackboard)
  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.RUNNING then
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.SUCCESS
  end
  return self.status
end

function AlwaysSuccess:reset()
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Forces the result of its child to be FAILURE (unless running).
---@class LOVElyTree.Decorators.AlwaysFail : LOVElyTree.Node
local AlwaysFail = {}
AlwaysFail.__index = AlwaysFail
function AlwaysFail.new(child)
  local obj = Node()
  setmetatable(obj, AlwaysFail)
  obj.child = child
  obj.node_type = "AlwaysFail"
  obj:reset()
  return obj
end

function AlwaysFail:update(dt, blackboard)
  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.RUNNING then
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.FAILURE
  end
  return self.status
end

function AlwaysFail:reset()
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Limits the total execution time of its child node.
---@class LOVElyTree.Decorators.TimeLimit : LOVElyTree.Node
local TimeLimit = {}
TimeLimit.__index = TimeLimit
function TimeLimit.new(child, limit)
  local obj = Node()
  setmetatable(obj, TimeLimit)
  obj.child = child
  obj.limit = limit
  obj.node_type = "TimeLimit"
  obj:reset()
  return obj
end

function TimeLimit:update(dt, blackboard)
  if self.timer < self.limit then
    local stat = self.child:update(dt, blackboard)
    if stat ~= RESULT.RUNNING then
      self.status = stat
      return self.status
    end
    self.timer = self.timer + dt
    if self.timer >= self.limit then
      self.status = RESULT.FAILURE
    else
      self.status = RESULT.RUNNING
    end
  else
    self.status = RESULT.FAILURE
  end
  return self.status
end

function TimeLimit:reset()
  self.timer = 0
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Limits the number of times its child node can be executed.
---@class LOVElyTree.Decorators.ExecutionLimit : LOVElyTree.Node
local ExecutionLimit = {}
ExecutionLimit.__index = ExecutionLimit
function ExecutionLimit.new(child, max_exec)
  local obj = Node()
  setmetatable(obj, ExecutionLimit)
  obj.child = child
  obj.max_exec = max_exec or 1
  obj.node_type = "ExecutionLimit"
  obj:reset()
  return obj
end

function ExecutionLimit:update(dt, blackboard)
  if self.exec_count >= self.max_exec then
    self.status = RESULT.FAILURE
    return self.status
  end
  local stat = self.child:update(dt, blackboard)
  if stat ~= RESULT.RUNNING then
    self.exec_count = self.exec_count + 1
    self.child:reset()
  end
  self.status = stat
  return self.status
end

function ExecutionLimit:reset()
  self.exec_count = 0
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Continuously executes its child node until it fails. Child is executed once per update.
--- Beware that this node will run indefinitely if the child node never fails.
---@class LOVElyTree.Decorators.UntilFail : LOVElyTree.Node
local UntilFail = {}
UntilFail.__index = UntilFail
function UntilFail.new(child)
  local obj = Node()
  setmetatable(obj, UntilFail)
  obj.child = child
  obj.node_type = "UntilFail"
  obj:reset()
  return obj
end

function UntilFail:update(dt, blackboard)
  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.FAILURE then
    self.status = RESULT.FAILURE
  elseif stat == RESULT.SUCCESS then
    self.child:reset() -- Restart the child immediately upon success.
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.RUNNING
  end
  return self.status
end

function UntilFail:reset()
  self.status = RESULT.IDLE
  self.child:reset()
end

--- Continuously executes its child node until it succeeds. Child is executed once per update.
--- Beware that this node will run indefinitely if the child node never succeeds.
---@class LOVElyTree.Decorators.UntilSuccess : LOVElyTree.Node
local UntilSuccess = {}
UntilSuccess.__index = UntilSuccess
function UntilSuccess.new(child)
  local obj = Node()
  setmetatable(obj, UntilSuccess)
  obj.child = child
  obj.node_type = "UntilSuccess"
  obj:reset()
  return obj
end

function UntilSuccess:update(dt, blackboard)
  local stat = self.child:update(dt, blackboard)
  if stat == RESULT.SUCCESS then
    self.status = RESULT.SUCCESS
  elseif stat == RESULT.FAILURE then
    self.child:reset() -- Restart the child immediately upon failure.
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.RUNNING
  end
  return self.status
end

function UntilSuccess:reset()
  self.status = RESULT.IDLE
  self.child:reset()
end

local Decorators = {
  Repeat = Repeat.new,
  Invert = Invert.new,
  Retry = Retry.new,
  AlwaysSuccess = AlwaysSuccess.new,
  AlwaysFail = AlwaysFail.new,
  TimeLimit = TimeLimit.new,
  ExecutionLimit = ExecutionLimit.new,
  UntilFail = UntilFail.new,
  UntilSuccess = UntilSuccess.new,
}

return Decorators
