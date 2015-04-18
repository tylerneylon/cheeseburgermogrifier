--[[ ld32/src/shot.lua

A class for shots fired.

--]]

require 'strict'  -- Enforce careful global variable usage.


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg      = require 'dbg'
local draw     = require 'draw'
local walls    = require 'walls'


--------------------------------------------------------------------------------
-- Utility functions.
--------------------------------------------------------------------------------

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


--------------------------------------------------------------------------------
-- The Shot class.
--------------------------------------------------------------------------------

local Shot = {}

-- This accepts and thinks mostly in terms of grid coords.
function Shot:new(g_pt, dir)
  -- We expect dir to be essentially a unit vector.
  assert(math.abs(norm(dir) - 1) < 0.001)
  local s = { gx = g_pt[1], gy = g_pt[2], dir = dir }
  return setmetatable(s, {__index = self})
end

function Shot:draw()
  local x1, y1 = walls.grid_to_virt_pt(self.gx, self.gy)
  local x2, y2 = walls.grid_to_virt_pt(self.gx + self.dir[1] * dbg.shot_len,
                                       self.gy + self.dir[2] * dbg.shot_len)
  love.graphics.setLineWidth(3)
  love.graphics.setColor({60, 160, 220})
  draw.line(x1, y1, x2, y2)
  love.graphics.setLineWidth(1)
end

function Shot:update(dt)
  self.gx = self.gx + dt * self.dir[1] * dbg.shot_speed
  self.gy = self.gy + dt * self.dir[2] * dbg.shot_speed
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Shot
