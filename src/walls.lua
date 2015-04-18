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

local function sign(x)
  if x < 0 then return -1 end
  if x > 0 then return  1 end
  return 0
end

-- Returns the size of the given 2-vector.
local function norm(v)
  return math.sqrt(v[1] ^ 2 + v[2] ^ 2)
end

-- Transforms the given 2-vector into a unit vector.
local function normalize(v)
  local n = norm(v)
  v[1] = v[1] / n
  v[2] = v[2] / n
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

-- Returns w, h (width, height) for the current level.
-- In virt coords.
function walls.sprite_size()
  return 2 / g.w * sprite_scale, 2 / g.h * sprite_scale
end

-- Same as walls.sprite_size, but the return value is
-- in grid coords.
function walls.grid_sprite_size()
  return sprite_scale, sprite_scale
end

function walls.grid_to_virt_pt(gx, gy)
  local vx = 2 * (gx - 1) / g.w - 1
  local vy = 2 * (gy - 1) / g.h - 1
  return vx, vy
end

-- Supporting function for grid_pts_can_see_each_other.
-- This expects dir ~= 0.
local function move_by_one(p, dir)
  if dir > 0 then
    return math.floor(p + 1)
  else
    return math.ceil(p - 1)
  end
end

function walls.grid_pt_hits_a_wall(gx, gy)
  for x = math.ceil(gx - 1), math.floor(gx) do
    for y = math.ceil(gy - 1), math.floor(gy) do
      if g[x] and g[x][y] == 1 then return true end
    end
  end
  return false
end

-- TODO Remove the redundancy between the following two functions.

-- Returns either false or the first point along the ray where we
-- hit a wall.
function walls.ray_hits_at(pt, dir)
  assert(pt and dir)
  local dst = {pt[1], pt[2]}  -- A local copy we can edit.
  dir = {dir[1], dir[2]}      -- A local copy we can edit.
  normalize(dir)

  while pt[1] >= 0 and pt[1] <= (g.w + 1) and
        pt[2] >= 0 and pt[2] <= (g.h + 1) do
    local t = {math.huge, math.huge}
    local q = {}
    for i = 1, 2 do
      if dir[i] ~= 0 then
        q[i] = move_by_one(pt[i], dir[i])
        t[i] = (q[i] - pt[i]) / dir[i]
      end
    end
    local ind = 1
    if t[2] < t[1] then ind = 2 end
    for i = 1, 2 do
      pt[i] = pt[i] + t[ind] * dir[i]
    end
    if walls.grid_pt_hits_a_wall(pt[1], pt[2]) then
      return pt
    end
  end
  return false  -- There was no collision.
end

-- Tests if walls block the line of sight between the two given points.
function walls.grid_pts_can_see_each_other(pt1, pt2)
  -- We'll cast a ray from gx1, gy1 toward the other point.
  local pt  = {pt1[1], pt1[2]}  -- Copy to avoid changing it.
  local dst = pt2
  local dir = {dst[1] - pt[1], dst[2] - pt[2]}
  normalize(dir)

  while sign(dir[1]) == sign(dst[1] - pt[1]) and
        sign(dir[2]) == sign(dst[2] - pt[2]) do
    local t = {math.huge, math.huge}
    local q = {}
    for i = 1, 2 do
      if dir[i] ~= 0 then
        q[i] = move_by_one(pt[i], dir[i])
        t[i] = (q[i] - pt[i]) / dir[i]
      end
    end
    local ind = 1
    if t[2] < t[1] then ind = 2 end
    for i = 1, 2 do
      pt[i] = pt[i] + t[ind] * dir[i]
    end
    if walls.grid_pt_hits_a_wall(pt[1], pt[2]) then
      return false  -- They can't see each other.
    end
  end
  return true  -- They can see each other.
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
