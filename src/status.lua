--[[ ld32/src/status.lua

A module to help with drawing the status bar.

--]]

require 'strict'  -- Enforce careful global variable usage.

local status = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local full_heart, empty_heart


--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function status.draw(hero)
  local win_w, win_h = love.graphics.getDimensions()
  local x = 10
  local dx, dy = full_heart:getWidth(), full_heart:getHeight()
  love.graphics.setColor({255, 255, 255})
  for i = 1, 3 do
    local img = full_heart
    if i > hero.health then img = empty_heart end
    love.graphics.draw(img, x, win_h - dy)
    x = x + dx
  end
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

full_heart  = love.graphics.newImage('img/full_heart.png')
empty_heart = love.graphics.newImage('img/empty_heart.png')


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return status
