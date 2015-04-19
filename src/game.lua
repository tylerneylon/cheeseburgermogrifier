--[[ ld32/src/game.lua


--]]

require 'strict'  -- Enforce careful global variable usage.

local game = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim        = require 'anim'
local Baddy       = require 'baddy'
local dbg         = require 'dbg'
local draw        = require 'draw'
local events      = require 'events'
local Hero        = require 'hero'
local status      = require 'status'
local walls       = require 'walls'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local baddies = {}
local hero
local you_died_image
local you_won_image

-- TEMP normally start with level_num = 0
local level_num = 0

local clock = 0

local baddy_last_added_at = 0
local next_baddy_to_add = 1


--------------------------------------------------------------------------------
-- Internal functions.
--------------------------------------------------------------------------------

local function pr(...)
  print(string.format(...))
end

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

local function max(...)
  local vals = {...}
  local m = vals[1]
  for i = 2, #vals do
    if vals[i] > m then m = vals[i] end
  end
  return m
end

local abs = math.abs -- Conveniently shorter name.

local function add_last_level_baddy()
  local baddy_info = {
    { {13, 3}, {12, 3}, {12, 2}, {3, 2}, {12, 2} },
    { {13, 10}, {3, 10}, {12, 10} }
  }
  local info = baddy_info[next_baddy_to_add]
  local b = Baddy:new(info[1][1], info[1][2])
  for i = 2, #info do
    b:add_pace_pt(info[i][1], info[i][2])
  end
  table.insert(baddies, b)

  next_baddy_to_add = (next_baddy_to_add % 2) + 1
  baddy_last_added_at = clock
end


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function game.update(dt)
  clock = clock + dt

  if game.villain and clock - baddy_last_added_at > 5 then
    add_last_level_baddy()
  end

  -- Update the baddies.
  if not game.is_won then
    for _, baddy in pairs(baddies) do
      baddy:update(dt, hero)
    end
  end

  -- Update the hero; returns true when the hero reaches the end of the level.
  if hero:update(dt, baddies) then
    local level_intro = require 'level_intro'
    level_intro.show_intro_for_level(level_num + 1)
  end

  if game.villain and game.villain.health == 0 and not game.is_won then
    -- Put any one-time game-won actions here.
    game.is_won = true
  end
end
 
function game.draw()
  walls.draw()

  for _, baddy in pairs(baddies) do
    if not game.is_won or baddy.is_cheeseburger then
      baddy:draw()
    end
  end
  hero:draw()
  status.draw(hero)

  if hero.dead then
    draw.img_w_mid_pt(you_died_image, 0, 0)
  else
    if game.is_won then
      love.graphics.setColor(draw.white)
      draw.img_w_mid_pt(you_won_image, 0, 0)
    end
  end
end

function game.keypressed(key, isrepeat)
  if isrepeat then return end
  hero:key_down(key)
end

function game.keyreleased(key)
  hero:key_up(key)
end

function game.next_level()
  clock = 0  -- Restart the clock so last-level baddies don't spawn instantly.
  level_num = level_num + 1
  walls.load_level(level_num)
  baddies = walls.new_baddies_for_level(level_num)
  -- Give the status module a way to see how much health the villain has.
  if #baddies > 0 and baddies[1].is_villain then
    game.villain = baddies[1]
  end
  hero.gx, hero.gy = walls.get_hero_start_pos_for_level(level_num)
  hero.keys_down = {}

  --pr('Just set hero grid pos to %d, %d', hero.gx, hero.gy)
  --pr('#baddies = %d', #baddies)
end

function game.take_over_and_next_level()
  love.give_control_to(game)
  game.next_level()
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

baddies = walls.new_baddies_for_level(1)

hero = Hero:new(8, 8)

you_died_image = love.graphics.newImage('img/you_died2.png')
assert(you_died_image)
you_won_image = love.graphics.newImage('img/you_won.png')
assert(you_won_image)


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return game
