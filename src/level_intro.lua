--[[ ld32/src/level_intro.lua

A control-level module to draw title cards
for individual levels.

--]]


require 'strict'  -- Enforce careful global variable usage.

local level_intro = {}


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local level_num = 0
local level_image
local num_images = {}


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function level_intro.update(dt)
end
 
function level_intro.draw()
end

function level_intro.keypressed(key, isrepeat)
end

function level_intro.keyreleased(key)
end

function level_intro.show_intro_for_level(level_num)
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

level_image = love.graphics.newImage('img/level.png')
assert(level_image)

for i = 0, 8 do
  num_images[i] = love.graphics.newImage('img/' .. i .. '.png')
  assert(num_images[i])
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return level_intro
