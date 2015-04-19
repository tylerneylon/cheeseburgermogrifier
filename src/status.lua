--[[ ld32/src/status.lua

A module to help with drawing the status bar.

--]]

require 'strict'  -- Enforce careful global variable usage.

local status = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg      = require 'dbg'
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
  for i = 1, dbg.max_health do
    local img = full_heart
    if i > hero.health then img = empty_heart end
    love.graphics.draw(img, x, win_h - dy)
    x = x + dx
  end

  local game = require 'game'
  if game.villain then
    -- Draw the enemy health.
    love.graphics.setColor(draw.white)
    x = x + 150
    love.graphics.printf('enemy', x, win_h - dy * 0.7 , 100)
    x = x + 50
    local h = 20
    -- Draw the health outline.
    love.graphics.rectangle('line', x, win_h - 25, 400, h)
    -- Draw the health bar itself.
    love.graphics.setColor({255, 0, 0})
    local w = 390 * (game.villain.health / dbg.villain_max_health)
    love.graphics.rectangle('fill', x + 5, win_h - 20, w, h - 10)
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
