--[[ ld32/src/walls.lua

Functions for working with walls.

--]]

require 'strict'  -- Enforce careful global variable usage.

local walls = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Internal level data.
--------------------------------------------------------------------------------

local level = [[
11111111111111
1            1
1            1
1            1
1            1
1            1
1     11111111
1            1
1     11111111
1            1
1            1
11111111111111
]]

local g = {}  -- Set during initialization.

local sprite_scale = 0.85


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

_ = 0

-- Returns a tile grid. The lower-left corner is point (1, 1); it's 1-indexed.
local function get_wall_grid()
  local g = {}  -- This is the grid.
  local first_line = level:match('(.-)\n')
  g.w = #first_line
  _, g.h = level:gsub('\n', '')  -- Count the number of lines.
  local x, y = 1, g.h
  for line in level:gmatch('(.-)\n') do
    for i = 1, #line do
      if g[x] == nil then g[x] = {} end
      local c = line:sub(i, i)
      if c == '1' then
        g[x][y] = 1
      else
        g[x][y] = 0
      end
      x = x + 1
    end
    x = 1
    y = y - 1
  end
  return g
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function walls.draw()
  local w, h = 2 / g.w, 2 / g.h
  --print('w, h =', w, h)
  local x, y = -1, 1 - h
  for gy = g.h, 1, -1 do
    for gx = 1, g.w do
      if g[gx][gy] == 1 then
        --print(string.format('drawing: %10g, %10g, %10g, %10g', x, y, w, h))
        draw.rect(x, y, w, h)
      end
      x = x + w
    end
    x = -1
    y = y - h
  end
end

function walls.hit_test(x, y, w, h)

  -- Box radii.
  local rw, rh = w / 2, h / 2
  -- Box center.
  local cx, cy = x + rw, y + rh

  -- Ok, this is not efficient. But probably good enough anyway.

  local function to_virt_box(gx, gy)
    local rw, rh = 1 / g.w, 1 / g.h
    local cx = 2 * (gx - 1) / g.w - 1 + rw
    local cy = 2 * (gy - 1) / g.h - 1 + rh
    return cx, cy, rw, rh
  end

  local function is_a_hit(gx, gy)
    local w_cx, w_cy, w_rw, w_rh = to_virt_box(gx, gy)
    if math.abs(w_cx - cx) < w_rw + rw and 
       math.abs(w_cy - cy) < w_rh + rh then

       return true
     end
    return false
  end

  for gy = 1, g.h do
    for gx = 1, g.w do
      if g[gx][gy] == 1 and is_a_hit(gx, gy) then
        return true
      end
    end
  end

  return false
end

function walls.sprite_hit_test(gx, gy)
  local x, y = walls.grid_to_virt_pt(gx, gy)
  local w = sprite_scale / g.w * 2
  local h = sprite_scale / g.h * 2
  return walls.hit_test(x, y, w, h)
end

-- Returns sw, sh (width, height) for the current level.
function walls.sprite_size()
  return 2 / g.w * sprite_scale, 2 / g.h * sprite_scale
end

function walls.grid_to_virt_pt(gx, gy)
  local vx = 2 * (gx - 1) / g.w - 1
  local vy = 2 * (gy - 1) / g.h - 1
  return vx, vy
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

-- If we ever change levels, we'll want to update g with each new level.
g = get_wall_grid()


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return walls
