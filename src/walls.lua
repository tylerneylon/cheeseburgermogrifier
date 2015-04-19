--[[ ld32/src/walls.lua

Functions for working with walls.

--]]

require 'strict'  -- Enforce careful global variable usage.

local walls = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg      = require 'dbg'
local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Internal globals, except level data which is below.
--------------------------------------------------------------------------------

local g = {}  -- Set during initialization.

local sprite_scale = 0.85


--------------------------------------------------------------------------------
-- Internal level data.
--------------------------------------------------------------------------------

local levels = {
  -- Level 0.
[[
11111111111111
1           11
1           11
1            2
1           11
1           11
1           11
1           11
1           11
1           11
1           11
11111111111111
]],

  -- Level 1.
[[
11111111111111
11           1
11           1
3            1
11           1
11           1
11   111111111
11           2
11   111111111
11           1
11           1
11111111111111
]],

  -- Level 2.
[[
11111111111111
11           1
11 1111 1111 1
11    1 12   1
11 1111 1111 1
11    1 1    1
11    1 1    1
3  1111 1111 1
11    1 1    1
11 1111 1111 1
11           1
11111111111111
]],

  -- Level 3.
[[
11111111111111
11           1
11           1
11 111111311 1
11           1
11 1       1 1
11 1       1 1
11 1       1 1
11           1
11    111    1
2            1
11111111111111
]],

  -- Level 4.
[[
11111111111111
11           3
1111 11 11 111
1111 11 11 111
1111 11 11 111
1111111 111111
1111111 111111
1111 11 11 111
1111 11 11 111
1111 11 11 111
11           2
11111111111111
]],

  -- Level 5.
[[
11111111111111
3           11
11 1 1  111 11
11 1 1   1  11
11 1 1   1  11
11 111   1  11
11 1 1   1  11
11 1 1   1  11
11 1 1  111 11
11          11
11           2
11111111111111
]],

  -- Level 6.
[[
11111111111111
11    11     2
11 11 11 11 11
11 11 11 11 11
11 11    11 11
11 11 11 11 11
11 11 11 11 11
11 11    11 11
11 11 11 11 11
11 11 11 11 11
3     11    11
11111111111111
]],

  -- Level 7.
[[
11111111111111
3  11111111111
11          11
1111 1 1111 11
1111 1 1111 11
1111 1 1111  2
1111 1 1111 11
1111 1      11
1111 111111111
1111 111111111
11111111111111
11111111111111
]],

  -- Level 8.
[[
11111111111111
11    11    11
11           4
11 1      1 11
11 1 1111 1 11
3  1      1 11
11 1      1 11
11 1      1 11
11 1 1111 1 11
11 1      1  4
11    11    11
11111111111111
]],
}

-- Each baddy datum starts with the level number, then their initial point;
-- after that is a sequence of pace points.
local baddy_data = {
  -- Level 1.
  -- (none)

  -- Level 2.
  { 2, {8, 5}, {7, 5}, {10, 5} }
}

-- The grid point where the hero starts in each level.
local hero_start = {
  { 3, 3 },    -- Level 0.
  { 2, 9 },
  { 2, 5 },
  { 10, 10 },
  { 13, 11 },  -- Level 4.
  {  2, 11 },
  {  2,  2 },
  {  2, 11 },
  {  2,  7 }
}

local level = levels[1]


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
      if c == ' ' then
        g[x][y] = 0
      else
        g[x][y] = tonumber(c)
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

local function pr(...)
  print(string.format(...))
end

local function grid_type_is_door(grid_type)
  return grid_type == 2
end

-- First pair is floating pt, second pair is an integer corner.
local function grid_pt_hits_door(gx, gy, crnr_x, crnr_y)
  gx, gy = gx + dbg.char_bd_w, gy + dbg.char_bd_h
  local cx, cy = crnr_x + 0.5, crnr_y + 0.5
  local door_extra = 0.2
  local w = dbg.char_bd_w + 0.5 + door_extra
  local h = dbg.char_bd_h + 0.5 + door_extra
  return math.abs(cx - gx) < w and
         math.abs(cy - gy) < h
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
      if g[gx][gy] ~= 0 then
        --print(string.format('drawing: %10g, %10g, %10g, %10g', x, y, w, h))
        draw.rect(x, y, w, h)
        love.graphics.setColor(draw.black)

        if dbg.do_draw_bounds then
          local eps = 0.01
          draw.rect(x + eps, y + eps, w - 2 * eps, h - 2 * eps, draw.black, 'line')
          draw.str(tostring(g[gx][gy]), x, y + h / 2, w, 'center')
        end
      end
      x = x + w
    end
    x = -1
    y = y - h
  end
end

-- The inputs are in virtual coords.
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
      if g[gx][gy] ~= 0 and is_a_hit(gx, gy) then
        return true
      end
    end
  end

  return false
end

function walls.does_hit_door(gx, gy)
  local corner_x, corner_y = math.floor(gx) - 1, math.floor(gy) - 1
  for x = corner_x, corner_x + 2 do
    for y = corner_y, corner_y + 2 do
      if g[x] and g[x][y] then  -- x or y may be out of range.
        if grid_type_is_door(g[x][y]) and grid_pt_hits_door(gx, gy, x, y) then
          return true
        end
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

-- This accepts either a single table or two numbers.
function walls.grid_to_virt_pt(gx, gy)
  if gy == nil then
    local pt = gx
    return {
      2 * (pt[1] - 1) / g.w - 1,
      2 * (pt[2] - 1) / g.h - 1
    }
  else
    local vx = 2 * (gx - 1) / g.w - 1
    local vy = 2 * (gy - 1) / g.h - 1
    return vx, vy
  end
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
      if g[x] and g[x][y] ~= 0 then return true end
    end
  end
  return false
end

-- Returns either false or the first point along the ray where we
-- hit a wall.
function walls.ray_hits_at(pt, dir)
  --pr('ray_hits_at: pt=(%g, %g) dir=(%g, %g)', pt[1], pt[2], dir[1], dir[2])

  assert(pt and dir)
  -- Make local copies we can edit.
  local pt = {pt[1], pt[2]}
  dir = {dir[1], dir[2]}
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
  --pr('grid_pts_can_see_each_other: (%g, %g) (%g, %g)', pt1[1], pt1[2], pt2[1], pt2[2])

  -- Turn this on to regularly see the wall grid (for the debuggings).
  --[[
  for y = 1, #g[1] do
    for x = 1, #g do
      io.write(string.format('%2d ', g[x][y]))
    end
    io.write('\n')
  end
  --]]

  local dir = {pt2[1] - pt1[1], pt2[2] - pt1[2]}
  normalize(dir)

  local hit_pt = walls.ray_hits_at(pt1, dir)
  if sign(pt2[1] - hit_pt[1]) ~= sign(dir[1]) or
     sign(pt2[2] - hit_pt[2]) ~= sign(dir[2]) then
    return true -- They can see each other; no wall collision.
  else
    return false
  end
end

function walls.new_baddies_for_level(level_num)
  local Baddy = require 'baddy'
  local baddies = {}
  for _, baddy_info in pairs(baddy_data) do
    if baddy_info[1] == level_num then
      pr('adding a baddy')
      local init_pt = baddy_info[2]
      local b = Baddy:new(init_pt[1], init_pt[2])
      for i = 3, #baddy_info do
        b:add_pace_pt(baddy_info[i][1], baddy_info[i][2])
      end
      table.insert(baddies, b)
    end
  end
  return baddies
end

function walls.load_level(level_num)
  level = levels[level_num]
  g = get_wall_grid()
end

function walls.get_hero_start_pos_for_level(level_num)
  pr('get_hero_start_pos_for_level(%d)', level_num)
  return unpack(hero_start[level_num])
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
