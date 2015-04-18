--[[ ld32/src/game.lua


--]]

require 'strict'  -- Enforce careful global variable usage.

local game = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim     = require 'anim'
local Baddy    = require 'baddy'
local dbg      = require 'dbg'
local draw     = require 'draw'
local events   = require 'events'
local walls    = require 'walls'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local hero_x, hero_y = 0.1, 0.1
local hero_w, hero_h -- This is currently set during initialization.
local h_dx, h_dy     = 0, 0
local keys_down      = {}

local baddies        = {}

--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function setup_grid_map_of_len(len)
  -- This is a linear-time Fisher-Yates shuffle.
  -- I find this to be less confusing than the Kansas City shuffle.
  grid_map = {}
  for i = 1, len do
    grid_map[i] = i
  end
  for i = 1, len do
    local j = math.random(i, len)
    grid_map[i], grid_map[j] = grid_map[j], grid_map[i]
  end
end

local function color_clamp(val)
  if val <   0 then return   0 end
  if val > 255 then return 255 end
  return val
end

local function setup_grid_colors(len)
  grid_colors = {}
  local base_color = {0, 200, 230}
  local max_offset = 90
  for i = 1, len do
    local c = {}
    for j = 1, 3 do
      c[j] = color_clamp(base_color[j] + math.random(-max_offset, max_offset))
    end
    grid_colors[i] = c
  end
end

local function gaarlicbread_color(let, num_let, grid, num_grid)
  local beats_of_let = {0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2}
  local beats_this_let = beats_of_let[let]
  if beats_this_let <= math.floor(num_beats) then
    return draw.black
  else
    return draw.white
  end
end

local function max(...)
  local vals = {...}
  local m = vals[1]
  for i = 2, #vals do
    if vals[i] > m then m = vals[i] end
  end
  return m
end

local function title_color(let, num_let, grid, num_grid)
  -- Apply a random map to the grid index.
  if grid_map == nil then setup_grid_map_of_len(num_grid) end
  grid = grid_map[grid]

  if grid_colors == nil then setup_grid_colors(num_grid) end

  local index = math.ceil(grid * #melody_eighths / num_grid)
  local tick_of_grid = melody_eighths[index]
  if tick_of_grid <= num_eighths then
    return grid_colors[grid]
  end
  local level = max(anim.row_levels[1], 110)
  return {level, level, level}
end

local abs = math.abs -- Conveniently shorter name.

local function draw_menu()
  local y_off = -0.6  -- The y offset of the menu's center.

  -- Determine the color.
  local level = math.floor((255 - anim.row_levels[5]) * 0.5)
  local color = {level, level, level}

  -- Draw the surrounding rectangle.
  local border_size = 0.02
  local border_w, border_h = 1, 0.4 - 2 * border_size
  local sx, sy = 1, 0
  for i = 1, 4 do
    local mid_x, mid_y = sx * border_w / 2, y_off + sy * border_h / 2
    sx, sy = -sy, sx
    local w, h = abs(sx) * border_w, abs(sy) * border_h
          w, h = w + border_size,    h + border_size
    draw.rect_w_mid_pt(mid_x, mid_y, w, h, color)
  end

  -- Draw the options.
  local block_size = 0.02
  local opts = {block_size = block_size}
  local line_height = 5 * block_size
  local leading = line_height + 2 * block_size
  local total_height = line_height * #menu_lines + 2 * block_size
  -- Start y at the middle of the top-most line.
  local top_y = y_off + (total_height - line_height) / 2
  local y = top_y
  for i = 1, #menu_lines do
    local x_align, y_align = 0.5, 0.5  -- We pass in the center/middle pt.
    font.draw_str(menu_lines[i], 0, y, x_align, y_align, color, opts)
    y = y - leading
  end

  -- Show which option is currently selected.
  y = top_y - (menu_choice - 1) * leading
  font.draw_str('>', -border_w / 2, y, 0, 0.5, color, opts)
end

-- Returns the theoretical outcome of moving based on the given keys and the
-- given start (x, y) point.
local function move_for_keys(x, y, keys)

  local hero_delta = {
    left  = { -1,  0 },
    right = {  1,  0 },
    up    = {  0,  1 },
    down  = {  0, -1 }
  }

  for key in pairs(keys) do
    local delta = hero_delta[key]
    if delta then
      x = x + delta[1] * dbg.hero_speed
      y = y + delta[2] * dbg.hero_speed
    end
  end

  return x, y
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function game.update(dt)

  assert(#keys_down <= 2)

  local w, h = hero_w, hero_h

  local function done(x, y)
    hero_x, hero_y = x, y
  end

  local x, y = move_for_keys(hero_x, hero_y, keys_down)
  if not walls.hit_test(x, y, w, h) then return done(x, y) end

  for key in pairs(keys_down) do
    local k = {[key] = true}
    local x, y = move_for_keys(hero_x, hero_y, k)
    if not walls.hit_test(x, y, w, h) then return done(x, y) end
  end
end
 
function game.draw()
  draw.hero(hero_x, hero_y, hero_w, hero_h)
  walls.draw()

  for _, baddy in pairs(baddies) do
    baddy:draw()
  end
end

function game.keypressed(key, isrepeat)
  if isrepeat then return end
  keys_down[key] = true
end

function game.keyreleased(key)
  keys_down[key] = nil
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

table.insert(baddies, Baddy:new(8, 5))

hero_w, hero_h = walls.sprite_size()


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return game
