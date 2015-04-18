--[[ ld32/src/main.lua


--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local anim   = require 'anim'
local dbg    = require 'dbg'
local events = require 'events'
local game   = require 'game'


--------------------------------------------------------------------------------
-- Love-based functions.
--------------------------------------------------------------------------------

-- This is a function we add to let anyone change modes.
function love.give_control_to(mode)
  local fn_names = {'draw', 'keypressed', 'keyreleased'}
  for _, fn_name in pairs(fn_names) do
    love[fn_name] = mode[fn_name]
  end
  love.mode_update = mode.update
end

function love.load()
  love.give_control_to(game)
end

function love.update(dt)
  -- Support debug slow-down.
  dbg.frame_offset = (dbg.frame_offset + 1) % dbg.cycles_per_frame
  if dbg.frame_offset ~= 0 then return end

  -- Hooks for module run loops.
  anim.update(dt)
  events.update(dt)

  -- This is the mode-specific update functions.
  love.mode_update(dt)
end
