local module = (...):match("(.-)[^%.]+$")
local Action = require(module .. "action")

---@return fun(...): LOVElyTree.Node
local function wrap(func)
    return function(...)
        return Action(func, ...)
    end
end

return wrap
