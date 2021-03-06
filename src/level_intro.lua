--[[ ld32/src/level_intro.lua

A control-level module to draw title cards
for individual levels.

--]]


require 'strict'  -- Enforce careful global variable usage.

local level_intro = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg  = require 'dbg'
local draw = require 'draw'
local game = require 'game'
local sounds = require 'sounds'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local level_num = 0
local level_image
local num_images = {}
local clock = 0
local took_over_at
local title_image

local interval = dbg.level_intro_interval

--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function level_intro.update(dt)
  clock = clock + dt

  if clock - took_over_at > interval then
    game.take_over_and_next_level()
  end
end
 
function level_intro.draw()
  draw.img(level_image, -0.8, -0.25)
  local num_img = num_images[level_num - 1]
  draw.img(num_img, 0.3, -0.25)

  draw.img(title_image, -0.8, -0.9)
end

function level_intro.keypressed(key, isrepeat)
end

function level_intro.keyreleased(key)
end

function level_intro.show_intro_for_level(new_level_num)
  level_num = new_level_num
  if level_num == 1 then
    sounds.intro:play()
    interval = 5
  else
    interval = dbg.level_intro_interval
  end
  love.give_control_to(level_intro)
  took_over_at = clock
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

level_image = love.graphics.newImage('img/level.png')
assert(level_image)

title_image = love.graphics.newImage('img/title.png')
assert(title_image)

for i = 0, 8 do
  num_images[i] = love.graphics.newImage('img/' .. i .. '.png')
  assert(num_images[i])
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return level_intro
