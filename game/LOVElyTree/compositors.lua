local module = (...):match("(.-)[^%.]+$")
local Node = require(module .. "node")
local RESULT = require(module .. "result")

--- Executes child nodes in order; succeeds if all children succeed and fails on the first failure.
--- This node may run more than one child at a time.
---@class LOVElyTree.Compositors.Sequence : LOVElyTree.Node
local Sequence = {}
Sequence.__index = Sequence

---@param children LOVElyTree.Node[]
---@return LOVElyTree.Compositors.Sequence
function Sequence.new(children)
  local obj = Node()
  setmetatable(obj, Sequence)
  obj.children = children
  obj.node_type = "Sequence"
  obj:reset()
  return obj
end

function Sequence:update(dt, blackboard)
  while self.current <= #self.children do
    local child = self.children[self.current]
    local stat = child:update(dt, blackboard)
    if stat == RESULT.RUNNING then
      self.status = RESULT.RUNNING
      return self.status
    elseif stat == RESULT.FAILURE then
      self.status = RESULT.FAILURE
      return self.status
    elseif stat == RESULT.SUCCESS then
      self.current = self.current + 1
    end
  end
  self.status = RESULT.SUCCESS
  return self.status
end

function Sequence:reset()
  self.current = 1
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
end

--- Executes children in order and returns SUCCESS on the first child success, fails when all children fail.
--- This node may run more than one child at a time.
---@class LOVElyTree.Compositors.Selector : LOVElyTree.Node
local Selector = {}
Selector.__index = Selector

---@param children LOVElyTree.Node[]
---@return LOVElyTree.Compositors.Selector
function Selector.new(children)
  local obj = Node()
  setmetatable(obj, Selector)
  obj.children = children
  obj.node_type = "Selector"
  obj:reset()
  return obj
end

function Selector:update(dt, blackboard)
  while self.current <= #self.children do
    local child = self.children[self.current]
    local stat = child:update(dt, blackboard)
    if stat == RESULT.RUNNING then
      self.status = RESULT.RUNNING
      return self.status
    elseif stat == RESULT.SUCCESS then
      self.status = RESULT.SUCCESS
      return self.status
    elseif stat == RESULT.FAILURE then
      self.current = self.current + 1
    end
  end
  self.status = RESULT.FAILURE
  return self.status
end

function Selector:reset()
  self.current = 1
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
end

--- Randomly selects one child to execute. Once a child is executed.
---@class LOVElyTree.Compositors.RandomOnce : LOVElyTree.Node
local RandomOnce = {}
RandomOnce.__index = RandomOnce

---@param children LOVElyTree.Node[]
---@return LOVElyTree.Compositors.RandomOnce
function RandomOnce.new(children)
  local obj = Node()
  setmetatable(obj, RandomOnce)
  obj.children = children
  obj.node_type = "RandomOnce"
  obj:reset()
  return obj
end

function RandomOnce:update(dt, blackboard)
  if not self.chosen then
    local idx = math.random(#self.children)
    self.chosen = self.children[idx]
  end
  local stat = self.chosen:update(dt, blackboard)
  self.status = stat
  return self.status
end

function RandomOnce:reset()
  self.chosen = nil
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
end

--- Executes all children in parallel; fails immediately if any child fails, else succeeds when all succeed.
--- This node doesn't wait for running children to finish if any child fails.
---@class LOVElyTree.Compositors.ParallelSequence : LOVElyTree.Node
local ParallelSequence = {}
ParallelSequence.__index = ParallelSequence

---@param children LOVElyTree.Node[]
function ParallelSequence.new(children)
  local obj = Node()
  setmetatable(obj, ParallelSequence)
  obj.children = children
  obj.node_type = "ParallelSequence"
  obj:reset()
  return obj
end

function ParallelSequence:update(dt, blackboard)
  local any_running = false
  for i, child in ipairs(self.children) do
    if self.results[i] == nil or self.results[i] == RESULT.RUNNING then
      local stat = child:update(dt, blackboard)
      if stat == RESULT.FAILURE then
        self.results[i] = stat
        self.status = RESULT.FAILURE
        return self.status
      elseif stat == RESULT.RUNNING then
        any_running = true
      else -- stat is SUCCESS
        self.results[i] = stat
      end
    elseif self.results[i] == RESULT.FAILURE then
      self.status = RESULT.FAILURE
      return self.status
    end
  end
  if any_running then
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.SUCCESS
  end
  return self.status
end

function ParallelSequence:reset()
  self.results = {}
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
end

--- Executes all children in parallel; returns SUCCESS immediately if any child success.
--- It waits for all children running to finish before returning SUCCESS or FAILURE.
---@class LOVElyTree.Compositors.ParallelSelector : LOVElyTree.Node
local ParallelSelector = {}
ParallelSelector.__index = ParallelSelector

---@param children LOVElyTree.Node[]
function ParallelSelector.new(children)
  local obj = Node()
  setmetatable(obj, ParallelSelector)
  obj.children = children
  obj.node_type = "ParallelSelector"
  obj:reset()
  return obj
end

function ParallelSelector:update(dt, blackboard)
  local any_running = false
  for i, child in ipairs(self.children) do
    if self.results[i] == nil or self.results[i] == RESULT.RUNNING then
      local stat = child:update(dt, blackboard)
      if stat == RESULT.SUCCESS then
        self.status = RESULT.SUCCESS
        return self.status
      elseif stat == RESULT.RUNNING then
        any_running = true
      end
      self.results[i] = stat
    elseif self.results[i] == RESULT.SUCCESS then
      self.status = RESULT.SUCCESS
      return self.status
    end
  end
  if any_running then
    self.status = RESULT.RUNNING
  else
    self.status = RESULT.FAILURE
  end
  return self.status
end

function ParallelSelector:reset()
  self.results = {}
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
end

--- Executes children in a random order until one succeeds. If one is running it will wait for it to finish.
--- Same as selector, it may run more than one child at a time.
---@class LOVElyTree.Compositors.RandomSelector : LOVElyTree.Node
local RandomSelector = {}
RandomSelector.__index = RandomSelector

---@param children LOVElyTree.Node[]
function RandomSelector.new(children)
  local obj = Node()
  setmetatable(obj, RandomSelector)
  obj.children = children
  obj.node_type = "RandomSelector"
  obj:reset()
  return obj
end

function RandomSelector:update(dt, blackboard)
  self.current = self.current or 1
  while self.current <= #self.order do
    local i = self.order[self.current]
    local child = self.children[i]
    local stat = child:update(dt, blackboard)
    if stat == RESULT.RUNNING then
      self.status = RESULT.RUNNING
      return self.status
    elseif stat == RESULT.SUCCESS then
      self.status = RESULT.SUCCESS
      return self.status
    elseif stat == RESULT.FAILURE then
      self.current = self.current + 1
    end
  end
  self.status = RESULT.FAILURE
  return self.status
end

function RandomSelector:reset()
  self.results = {}
  self.current = 1
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
  self.order = {}
  for i = 1, #self.children do table.insert(self.order, i) end
  for i = #self.order, 2, -1 do
    local j = math.random(i)
    self.order[i], self.order[j] = self.order[j], self.order[i]
  end
end

--- Executes children in random order; succeeds only if all children succeed.
--- This node may run more than one child at a time.
---@class LOVElyTree.Compositors.RandomSequence : LOVElyTree.Node
local RandomSequence = {}
RandomSequence.__index = RandomSequence

---@param children LOVElyTree.Node[]
function RandomSequence.new(children)
  local obj = Node()
  setmetatable(obj, RandomSequence)
  obj.children = children
  obj.node_type = "RandomSequence"
  obj:reset()
  return obj
end

function RandomSequence:update(dt, blackboard)
  self.current = self.current or 1
  while self.current <= #self.order do
    local i = self.order[self.current]
    local child = self.children[i]
    local stat = child:update(dt, blackboard)
    if stat == RESULT.RUNNING then
      self.status = RESULT.RUNNING
      return self.status
    elseif stat == RESULT.FAILURE then
      self.status = RESULT.FAILURE
      return self.status
    elseif stat == RESULT.SUCCESS then
      self.current = self.current + 1
    end
  end
  self.status = RESULT.SUCCESS
  return self.status
end

function RandomSequence:reset()
  self.results = {}
  self.current = 1
  self.status = RESULT.IDLE
  for _, child in ipairs(self.children) do child:reset() end
  self.order = {}
  for i = 1, #self.children do table.insert(self.order, i) end
  for i = #self.order, 2, -1 do
    local j = math.random(i)
    self.order[i], self.order[j] = self.order[j], self.order[i]
  end
end

local Compositors = {
  Sequence = Sequence.new,
  Selector = Selector.new,
  RandomOnce = RandomOnce.new,
  RandomSelector = RandomSelector.new,
  RandomSequence = RandomSequence.new,
  ParallelSequence = ParallelSequence.new,
  ParallelSelector = ParallelSelector.new,
}

return Compositors
