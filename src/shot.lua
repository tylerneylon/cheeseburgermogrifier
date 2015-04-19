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

local function complex_mult(p, q)
  return {p[1] * q[1] - p[2] * q[2], p[1] * q[2] + p[2] * q[1]}
end

local function cis(theta)
  return {math.cos(theta), math.sin(theta)}
end


--------------------------------------------------------------------------------
-- The Shot class.
--------------------------------------------------------------------------------

local Shot = {}

-- This accepts and thinks mostly in terms of grid coords.
function Shot:new(g_pt, dir)
  assert(g_pt and dir)
  -- We expect dir to be essentially a unit vector.
  assert(math.abs(norm(dir) - 1) < 0.001)
  local s = { gx = g_pt[1], gy = g_pt[2], dir = dir }
  s.ending_perc = 0
  s.hit_pt = walls.ray_hits_at({s.gx, s.gy}, s.dir)

  -- Set up random directions for hit blasts.
  s.hit_blasts = {}
  local num_blasts = math.random(5, 10)
  for i = 1, num_blasts do
    local blast = {
      dir = complex_mult({-s.dir[1], -s.dir[2]}, cis(math.random() * 2.0 - 1.0)),
      len = dbg.shot_len * math.random()
    }
    table.insert(s.hit_blasts, blast)
  end

  return setmetatable(s, {__index = self})
end

function Shot:draw()
  if self.done then return end

  local x1, y1 = walls.grid_to_virt_pt(self.gx, self.gy)
  local len = dbg.shot_len * (1 - self.ending_perc)
  local x2, y2 = walls.grid_to_virt_pt(self.gx + self.dir[1] * len,
                                       self.gy + self.dir[2] * len)
  love.graphics.setLineWidth(2)
  love.graphics.setColor({60, 160, 220})
  draw.line(x1, y1, x2, y2)
  love.graphics.setLineWidth(1)

  if self.ending_perc == 0 then return end

  for _, blast in pairs(self.hit_blasts) do
    local len = blast.len * self.ending_perc
    local to1 = self.hit_pt[1] + blast.dir[1] * len
    local to2 = self.hit_pt[2] + blast.dir[2] * len
    local x1, y1 = walls.grid_to_virt_pt(self.hit_pt[1], self.hit_pt[2])
    local x2, y2 = walls.grid_to_virt_pt(to1, to2)
    draw.line(x1, y1, x2, y2)
  end
end

function Shot:update(dt, hero)
  if self.done then return end

  self.gx = self.gx + dt * self.dir[1] * dbg.shot_speed
  self.gy = self.gy + dt * self.dir[2] * dbg.shot_speed

  local end_grid_pt = {
    self.gx + self.dir[1] * dbg.shot_len,
    self.gy + self.dir[2] * dbg.shot_len
  }
  local end_pt = walls.grid_to_virt_pt(end_grid_pt)
  local cx, cy, rw, rh = hero:virt_bd_box()
  if math.abs(cx - end_pt[1]) < rw and
     math.abs(cy - end_pt[2]) < rh then
    -- There hero was hit!
    hero:got_hit_by_blast_going_in_dir(self.dir)
    self.done = true
  end

  if self.hit_pt then
    local delta = { self.hit_pt[1] - self.gx, self.hit_pt[2] - self.gy }
    if sign(delta[1]) ~= sign(self.dir[1]) or sign(delta[2]) ~= sign(self.dir[2]) then
      self.done = true
    end
    local dist  = norm(delta) / norm(self.dir)
    if dist < dbg.shot_len then
      self.ending_perc = 1 - dist / dbg.shot_len
    end
  end
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return Shot
