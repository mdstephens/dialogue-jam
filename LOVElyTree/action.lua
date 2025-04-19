local module = (...):match("(.-)[^%.]+$")
local RESULT = require(module .. "result")

local function Action(action_constructor, ...)
  local args = { ... }
  local action_instance = action_constructor(unpack(args))
  local node = {}
  node._actionConstructor = action_constructor
  node._actionArgs = args
  node._action = action_instance

  node.node_type = action_instance.name or "Action"
  node.status = RESULT.IDLE

  function node:update(dt)
    self.status = self._action:update(dt)
    return self.status
  end

  function node:reset()
    self.status = RESULT.IDLE
    local instance_constructor = true

    -- Users can provide node cleanup logic here. Optionally allowing
    -- to discard the whole action by returning false or nil. This gives full control over actions
    if self._action.reset then
      instance_constructor = self._action:reset()
    end

    if instance_constructor then
      self._action = self._actionConstructor(unpack(self._actionArgs))
    end
  end

  return node
end

return Action
