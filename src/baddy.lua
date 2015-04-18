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

local dbg      = require 'dbg'
local draw     = require 'draw'
local Hero     = require 'hero'
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
-- The Baddy class.
--------------------------------------------------------------------------------

local Baddy = {w = 0.05, h = 0.4, delta = {0, 0}}

-- This accepts and thinks mostly in terms of
-- grid coords.
function Baddy:new(gx, gy)
  local b = { gx = gx, gy = gy }
  b.w,  b.h  = walls.sprite_size()
  b.gw, b.gh = walls.grid_sprite_size()
  return setmetatable(b, {__index = self})
end

function Baddy:can_see_hero(hero, do_draw)
  local see_x = hero.gx + hero.gw / 2
  local see_pts = {
    { see_x, hero.gy + 0.2 * hero.gh },
    { see_x, hero.gy + 0.8 * hero.gh }
  }

  local eye = { self.gx + 0.5 * self.gw,
                self.gy + 0.8 * self.gh }

  if do_draw then
    love.graphics.setColor({120, 120, 0})
    --love.graphics.setColor(draw.white) -- TEMP
    --love.graphics.setLineWidth(2)
    for _, see_pt in pairs(see_pts) do
      local x1, y1 = walls.grid_to_virt_pt(eye[1], eye[2])
      local x2, y2 = walls.grid_to_virt_pt(see_pt[1], see_pt[2])
      if walls.grid_pts_can_see_each_other(eye, see_pt) then
        love.graphics.setColor(draw.white)
      else
        love.graphics.setColor({120, 120, 0})
      end
      draw.line(x1, y1, x2, y2)
    end
  end


end

function Baddy:draw()
  local x, y = walls.grid_to_virt_pt(self.gx, self.gy)
  local w, h = self.w, self.h
  draw.hero(x, y, w, h, 'bad')

  -- TODO TEMP DEBUG
  if self.hero then
    self:can_see_hero(self.hero, true)
  end
end

function Baddy:set_dest_ind(ind)
  local d       = self.pace_pts[ind]
  self.dest     = d
  self.dest_ind = ind
  self.delta    = {d[1] - self.gx, d[2] - self.gy}
  normalize(self.delta)
end

function Baddy:did_reach_dest()
  local d     = self.dest
  local delta = {d[1] - self.gx, d[2] - self.gy}
  if sign(delta[1]) ~= sign(self.delta[1]) or
     sign(delta[2]) ~= sign(self.delta[2]) then
    return true
  end
  return false
end

function Baddy:add_pace_pt(gx, gy)
  if self.pace_pts == nil then
    self.pace_pts = {}
  end
  table.insert(self.pace_pts, {gx, gy})
  if #self.pace_pts == 1 then
    self:set_dest_ind(1)
  end
end

function Baddy:update(dt, hero)
  self.gx = self.gx + dt * self.delta[1] * dbg.baddy_speed
  self.gy = self.gy + dt * self.delta[2] * dbg.baddy_speed

  if self:did_reach_dest() then
    self.x, self.y = self.dest[1], self.dest[2]
    local new_ind = (self.dest_ind % #self.pace_pts) + 1
    self:set_dest_ind(new_ind)
  end

  -- Check to see if we can see the hero.

  -- TEMP
  self.hero = hero

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
