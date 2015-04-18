--[[ ld32/src/baddy.lua

A class to encapsulate bad person behavior.

The traditional term is bad guy but 
some bad people may be women or choose to not
gender-identify.

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'
local walls    = require 'walls'


--------------------------------------------------------------------------------
-- The Baddy class.
--------------------------------------------------------------------------------

local Baddy = {w = 0.05, h = 0.4}

-- This accepts and thinks mostly in terms of
-- grid coords.
function Baddy:new(gx, gy)
  local b = { gx = gx, gy = gy }
  b.w, b.h = walls.sprite_size()
  return setmetatable(b, {__index = self})
end

function Baddy:draw()
  local x, y = walls.grid_to_virt_pt(self.gx, self.gy)
  local w, h = self.w, self.h
  draw.hero(x, y, w, h)
end

function Baddy:update(dt)
end

function Baddy:score_up(ball)
  sounds.point:play()
  self.score = self.score + ball:value()
  Ball:new(ball)
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Baddy
