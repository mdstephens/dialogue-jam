local module = (...):match("(.-)[^%.]+$")
local RESULT = require(module .. "result") ---@module "LOVElyTree.result"
local compositors = require(module .. "compositors") ---@module "LOVElyTree.compositors"
local decorators = require(module .. "decorators") ---@module "LOVElyTree.decorators"
local actions = require(module .. "actions") ---@module "LOVElyTree.actions"
local tree = require(module .. "behavior_tree") ---@module "LOVElyTree.behavior_tree"
local action = require(module .. "action") ---@module "LOVElyTree.action"
local wrap = require(module .. "wrapaction") ---@module "LOVElyTree.wrapaction"

---@class LOVElyTree
local LT = {
    Compositors = compositors,
    Decorators = decorators,
    Actions = actions,
    BehaviorTree = tree,
    Action = action,
    RESULT = RESULT,
    WrapAction = wrap
}

return LT
