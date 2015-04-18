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


--------------------------------------------------------------------------------
-- The Baddy class.
--------------------------------------------------------------------------------

local Baddy = {w = 0.05, h = 0.4}

function Baddy:new(x, y)
  local b = {x = x, y = y, score = 0}
  return setmetatable(b, {__index = self})
end

function Baddy:draw()
  local w, h = self.w, self.h
  draw.hero(self.x, self.y, self.w, self.h)
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
