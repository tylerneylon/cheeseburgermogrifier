--[[ ld32/src/hero.lua

A class to encapsulate hero behavior.

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

-- Returns the theoretical outcome of moving based on the given keys and the
-- given start (x, y) point.
local function move_for_keys(x, y, keys)

  local hero_delta = {
    left  = { -1,  0 },
    right = {  1,  0 },
    up    = {  0,  1 },
    down  = {  0, -1 }
  }

  for key in pairs(keys) do
    local delta = hero_delta[key]
    if delta then
      x = x + delta[1] * dbg.hero_speed
      y = y + delta[2] * dbg.hero_speed
    end
  end

  return x, y
end


--------------------------------------------------------------------------------
-- The Hero class.
--------------------------------------------------------------------------------

local hero_w, hero_h = walls.sprite_size()

local Hero = {w = hero_w, h = hero_h}

-- This accepts and thinks mostly in terms of grid coords.
function Hero:new(gx, gy)
  local h = { gx = gx, gy = gy, keys_down = {} }
  h.gw, h.gh = walls.grid_sprite_size()
  h.health = dbg.max_health
  return setmetatable(h, {__index = self})
end

function Hero:draw()
  local x, y = walls.grid_to_virt_pt(self.gx, self.gy)
  local w, h = self.w, self.h
  draw.hero(x, y, w, h, 'good')

  if dbg.do_draw_bounds then
    local cx, cy, rw, rh = self:virt_bd_box()
    draw.rect_w_mid_pt(cx, cy, 2 * rw, 2 * rh, {255, 0, 0}, 'line')
  end
end

-- This returns cx, cy, rw, rh, which means the center point and the
-- radius-ish width and height; all in virtual coords.
function Hero:virt_bd_box(gx, gy)
  gx = gx or self.gx
  gy = gy or self.gy
  local x, y = walls.grid_to_virt_pt(gx, gy)
  local rw, rh = self.w * 0.2, self.h * 0.45
  local cx, cy = x + self.w / 2, y + self.h / 2
  return cx, cy, rw, rh
end

function Hero:update(dt)

  assert(#self.keys_down <= 2)

  local w, h = self.w, self.h
  local function done(gx, gy)
    self.gx, self.gy = gx, gy
  end

  local cx, cy, rw, rh = self:virt_bd_box()

  local gx, gy = move_for_keys(self.gx, self.gy, self.keys_down)
  local cx, cy = self:virt_bd_box(gx, gy)
  if not walls.hit_test(cx - rw, cy - rh, 2 * rw, 2 * rh) then
    return done(gx, gy)
  end

  for key in pairs(self.keys_down) do
    local k = {[key] = true}
    local gx, gy = move_for_keys(self.gx, self.gy, k)
    local cx, cy = self:virt_bd_box(gx, gy)
    if not walls.hit_test(cx - rw, cy - rh, 2 * rw, 2 * rh) then
      return done(gx, gy)
    end
  end
end

function Hero:key_down(key)
  local keys_to_track = {
    up    = true,
    down  = true,
    left  = true,
    right = true
  }
  if not keys_to_track[key] then return end
  self.keys_down[key] = true
end

function Hero:key_up(key)
  self.keys_down[key] = nil
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Hero
