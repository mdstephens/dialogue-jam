---@enum LOVElyTree.Result
local RESULT = {
    IDLE = -1,
    SUCCESS = 0,
    RUNNING = 1,
    FAILURE = 2,
}

local reverse_mapping = {}
for k, v in pairs(RESULT) do
  reverse_mapping[v] = k
end

function RESULT.to_string(result) ---@diagnostic disable-line
  return reverse_mapping[result]
end

return RESULT