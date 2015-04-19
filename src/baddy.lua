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
local Shot     = require 'shot'
local walls    = require 'walls'


--------------------------------------------------------------------------------
-- Internal globals.
--------------------------------------------------------------------------------

local clock = 0
local shot_color = {200, 90, 90}
local cheeseburger_image


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
  b.shots = {}
  b.is_baddy = true
  return setmetatable(b, {__index = self})
end

-- This returns either false (if we can't see the hero) or
-- the point, in grid coords, that can be seen.
function Baddy:can_see_hero(hero, do_draw)
  do_draw = do_draw and dbg.do_draw_vis_lines
  assert(hero)
  local see_x = hero.gx + hero.gw / 2
  local see_pts = {
    { see_x, hero.gy + 0.2 * hero.gh },
    { see_x, hero.gy + 0.8 * hero.gh }
  }

  local eye = { self.gx + 0.5 * self.gw,
                self.gy + 0.5 * self.gh }

  if do_draw then
    love.graphics.setColor({120, 120, 0})
  end

  local can_see = false

  for _, see_pt in pairs(see_pts) do
    local x1, y1 = walls.grid_to_virt_pt(eye[1], eye[2])
    local x2, y2 = walls.grid_to_virt_pt(see_pt[1], see_pt[2])
    if walls.grid_pts_can_see_each_other(eye, see_pt) then
      if do_draw then love.graphics.setColor(draw.white) end
      can_see = {see_pt[1], see_pt[2]}
    else
      if do_draw then love.graphics.setColor({120, 120, 0}) end
    end
    if do_draw then draw.line(x1, y1, x2, y2) end
  end

  return can_see
end

function Baddy:draw()
  local x, y = walls.grid_to_virt_pt(self.gx, self.gy)
  local w, h = self.w, self.h

  if self.is_cheeseburger then
    draw.img(cheeseburger_image, x, y, w, h)
    return
  end

  draw.hero(x, y, w, h, 'bad')

  if self.hero and dbg.do_draw_vis_lines then
    self:can_see_hero(self.hero, true)
  end

  for i = #self.shots, 1, -1 do
    self.shots[i]:draw()
    if self.shots[i].done then
      table.remove(self.shots, i)
    end
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

function Baddy:can_shoot_now()
  if self.last_shot_fired_at == nil then return true end

  local time_since_last_shot = clock - self.last_shot_fired_at
  return time_since_last_shot > dbg.baddy_fire_interval
end

function Baddy:shoot_at(dest)
  local g_pt = { self.gx + 0.5 * self.gw, self.gy + 0.5 * self.gh }
  local dir = { dest[1] - g_pt[1], dest[2] - g_pt[2] }
  normalize(dir)
  table.insert(self.shots, Shot:new(g_pt, dir, shot_color))
  self.last_shot_fired_at = clock
end

-- This returns cx, cy, rw, rh, which means the center point and the
-- radius-ish width and height; all in virtual coords.
function Baddy:virt_bd_box(gx, gy)
  gx = gx or self.gx
  gy = gy or self.gy
  local x, y = walls.grid_to_virt_pt(gx, gy)
  local rw, rh = self.w * dbg.char_bd_w, self.h * dbg.char_bd_h
  local cx, cy = x + self.w / 2, y + self.h / 2
  return cx, cy, rw, rh
end

function Baddy:got_hit_by_blast_going_in_dir(dir)
  self.is_cheeseburger = true
end

function Baddy:update(dt, hero)
  clock = clock + dt

  for _, shot in pairs(self.shots) do
    shot:update(dt, hero)
  end

  -- We stop moving when we're cheeseburgers. Trust me on this one.
  if self.is_cheeseburger then return end

  self.gx = self.gx + dt * self.delta[1] * dbg.baddy_speed
  self.gy = self.gy + dt * self.delta[2] * dbg.baddy_speed

  if self:did_reach_dest() then
    self.x, self.y = self.dest[1], self.dest[2]
    local new_ind = (self.dest_ind % #self.pace_pts) + 1
    self:set_dest_ind(new_ind)
  end

  -- Check to see if we can see the hero.
  local seen_pt = self:can_see_hero(hero)
  if seen_pt and self:can_shoot_now() then
    self:shoot_at(seen_pt)
  end

  if dbg.do_draw_vis_lines then
    self.hero = hero
  end
end


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

cheeseburger_image = love.graphics.newImage('img/cheeseburger.png')


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Baddy
