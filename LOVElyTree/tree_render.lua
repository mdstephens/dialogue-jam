local module = (...):match("(.-)[^%.]+$")
local RESULT = require(module .. "result")

local BOX_HEIGHT = 40
local HORIZONTAL_SPACING = 10 -- Reduced from 20
local VERTICAL_SPACING = 40   -- Reduced from 50
local CORNER_RADIUS = 8       -- Slightly smaller radius
local MIN_BOX_WIDTH = 100     -- Slightly smaller min width

local function measure_node_text(node)
  local font = love.graphics.getFont()
  local node_type_width = font:getWidth(node.node_type)
  local status_width = font:getWidth(RESULT.to_string(node.status))
  return math.max(node_type_width, status_width) + HORIZONTAL_SPACING
end

local function get_children(node)
  if node.children then return node.children end
  if node.child then return { node.child } end
  return {}
end

local function compute_spacing_width(node)
  local width = measure_node_text(node)
  for _, child in ipairs(get_children(node)) do
    width = math.max(width, measure_node_text(child))
  end
  return math.max(width, MIN_BOX_WIDTH)
end

local function compute_subtree_width(node, spacing_width)
  local children = get_children(node)
  if #children == 0 then
    return spacing_width
  else
    local total = 0
    -- Use local spacing width for each subtree
    local local_spacing = compute_spacing_width(node)
    for i, child in ipairs(children) do
      total = total + compute_subtree_width(child, local_spacing)
      if i < #children then total = total + HORIZONTAL_SPACING end
    end
    return math.max(spacing_width, total)
  end
end

-- Previously I modified the node in place but that was ugly you know, a render function shouldn't mutate data. Render functions must be "pure" in that sense
-- And also having it this way allows to save the layout data, if you're lazy to save just call draw_tree and it will generate the layout each time, it's your CPU not mine
local function layout_tree(node, x, y)
  local box_width = math.max(measure_node_text(node), MIN_BOX_WIDTH)
  local spacing_width = compute_spacing_width(node)
  local subtree_width = compute_subtree_width(node, spacing_width)
  local data = {
    node = node,
    x = x + (subtree_width - spacing_width) / 2,
    y = y,
    width = box_width,
    children = {}
  }

  local children = get_children(node)
  if #children > 0 then
    local total_width = 0
    for _, child in ipairs(children) do
      total_width = total_width + compute_subtree_width(child, spacing_width)
    end
    total_width = total_width + HORIZONTAL_SPACING * (#children - 1)
    local start_x = x + (subtree_width - total_width) / 2
    for _, child in ipairs(children) do
      local child_subtree_width = compute_subtree_width(child, spacing_width)
      local child_data = layout_tree(child, start_x, y + BOX_HEIGHT + VERTICAL_SPACING)
      table.insert(data.children, child_data)
      start_x = start_x + child_subtree_width + HORIZONTAL_SPACING
    end
  end
  return data
end


local function get_color_for_status(status)
  if status == RESULT.SUCCESS then
    return { 0, 1, 0 }
  elseif status == RESULT.FAILURE then
    return { 1, 0, 0 }
  elseif status == RESULT.RUNNING then
    return { 1, 1, 0 }
  elseif status == RESULT.IDLE then
    return { 0.5, 0.5, 0.5 }
  else
    return { 1, 0, 1 }
  end -- Between you and me, this sholdn't happen
end

local function get_node_color(node)
  return get_color_for_status(node.status)
end

-- Do you think I was using shaders for this? LMAO
local function draw_dotted_line(x1, y1, x2, y2)
  local dashLength = 5
  local gapLength = 5
  local speed = -50
  local dx, dy = x2 - x1, y2 - y1
  local distance = math.sqrt(dx * dx + dy * dy)
  local angle = math.atan2(dy, dx)
  local offset = (love.timer.getTime() * speed) % (dashLength + gapLength)
  local current = -offset
  while current < distance do
    local startPos = math.max(current, 0)
    local endPos = math.min(current + dashLength, distance)
    if endPos > 0 then
      local sx = x1 + math.cos(angle) * startPos
      local sy = y1 + math.sin(angle) * startPos
      local ex = x1 + math.cos(angle) * endPos
      local ey = y1 + math.sin(angle) * endPos
      love.graphics.line(sx, sy, ex, ey)
    end
    current = current + dashLength + gapLength
  end
end

local function render_tree_from_layout(data)
  love.graphics.setLineWidth(2)

  -- Draw connectors for children first. I don't like lines going over boxes.
  for _, child in ipairs(data.children) do
    local child_col = get_node_color(child.node)
    love.graphics.setColor(child_col)
    local startX, startY = data.x + data.width / 2, data.y + BOX_HEIGHT
    local endX, endY = child.x + child.width / 2, child.y
    if data.node.status == RESULT.RUNNING and child.node.status == RESULT.RUNNING then
      draw_dotted_line(startX, startY, endX, endY)
    else
      love.graphics.line(startX, startY, endX, endY)
    end
    render_tree_from_layout(child)
  end

  -- Draw the current node box.
  local col = get_node_color(data.node)
  love.graphics.setColor(col[1], col[2], col[3], 0.3)
  love.graphics.rectangle("fill", data.x, data.y, data.width, BOX_HEIGHT, CORNER_RADIUS, CORNER_RADIUS)
  love.graphics.setColor(col[1], col[2], col[3], 1)
  love.graphics.rectangle("line", data.x, data.y, data.width, BOX_HEIGHT, CORNER_RADIUS, CORNER_RADIUS)
  local display_status = RESULT.to_string(data.node.status)
  -- Use node.prompt if available, otherwise fallback to node_type
  local node_text = data.node.prompt or data.node.node_type or "Node"
  love.graphics.printf(node_text .. "\n" .. display_status, data.x, data.y + 5, data.width, "center")
end

local function draw_tree(node, x, y)
  local data = layout_tree(node, x, y)
  render_tree_from_layout(data)
end

return {
  layout_tree = layout_tree, -- Generates the layout data needed to render the tree, this includes references to the tree node
  render_tree = render_tree_from_layout, -- This function renders the tree, it uses the layout data generated by layout_tree
  draw_tree = draw_tree,     -- This function generates the layout data and renders the tree in one call (not recommended for performance reasons)
}
