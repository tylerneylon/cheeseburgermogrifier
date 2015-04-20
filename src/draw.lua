--[[ ld32/src/draw.lua

Drawing functions. Surprise!

These drawing functions accept coordinates in a custom system where
[-1, -1] is the lower-left corner, and [1, 1] is the upper-right, like this:


 (-1,  1) ------ (1,  1)

    |               |
    |               |
    |   le screen   |
    |               |
    |               |
    
 (-1, -1) ------ (1, -1)


--]]

require 'strict'  -- Enforce careful global variable usage.


local draw = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local dbg = require 'dbg'


--------------------------------------------------------------------------------
-- Parameters.
--------------------------------------------------------------------------------

draw.border_size = 0.025


--------------------------------------------------------------------------------
-- Colors.
--------------------------------------------------------------------------------

draw.black   = {  0,   0,   0}
draw.cyan    = {  0, 255, 255}
draw.gray    = {120, 120, 120}
draw.green   = {  0, 210,   0}
draw.white   = {255, 255, 255}
draw.yellow  = {210, 150,   0}


--------------------------------------------------------------------------------
-- Utility functions.
--------------------------------------------------------------------------------

local function min(...)
  local t = {...}
  local val = t[1]
  for i = 2, #t do
    if t[i] < val then val = t[i] end
  end
  return val
end

local function win_size()
  local win_w, win_h = love.graphics.getDimensions()
  return win_w, win_h - dbg.status_height
end

local function pr(...)
  print(string.format(...))
end


--------------------------------------------------------------------------------
-- General drawing functions.
--------------------------------------------------------------------------------

-- x, y is the lower-left corner of the rectangle.
function draw.rect(x, y, w, h, color, mode)
  mode = mode or 'fill'

  -- Set the color.
  color = color or {255, 255, 255}
  love.graphics.setColor(color)

  -- Convert coordinates.
  local win_w, win_h = win_size()
  -- We invert y here since love.graphics treats the top as y=0,
  -- and we treat the bottom as y=0.
  x, y = (x + 1) * win_w / 2, (1 - y) * win_h / 2
  w, h = w * win_w / 2, h * win_h / 2

  -- Shift y since love.graphics draws from the upper-left corner.
  y = y - h

  -- Draw the rectangle.
  --pr('rect %g x %g', w, h)
  love.graphics.rectangle(mode, x, y, w, h)
end

function draw.img(img, x, y, w, h)

  -- Convert coordinates.
  local win_w, win_h = win_size()
  -- We invert y here since love.graphics treats the top as y=0,
  -- and we treat the bottom as y=0.
  x, y = (x + 1) * win_w / 2, (1 - y) * win_h / 2

  if w then
    w = w * win_w / 2
  else
    w = img:getWidth()
  end

  if h then
    h = h * win_h / 2
  else
    h = img:getHeight()
  end

  -- Shift y since love.graphics draws from the upper-left corner.
  y = y - h

  love.graphics.setColor(draw.white)

  -- Draw the rectangle.
  love.graphics.draw(img, x, y)
end

function draw.img_w_mid_pt(img, cx, cy, w, h)
  local win_w, win_h = win_size()
  if not w then w = 2 * img:getWidth()  / win_w end
  if not h then h = 2 * img:getHeight() / win_h end
  draw.img(img, cx - w / 2, cy - h / 2, w, h)
end

function draw.rect_w_mid_pt(mid_x, mid_y, w, h, color, mode)
  -- Set (x, y) to the lower-left corner of the rectangle.
  local x = mid_x - w / 2
  local y = mid_y - h / 2
  draw.rect(x, y, w, h, color, mode)
end

function draw.rotated_rect(mid_x, mid_y, w, h, color, angle)
  -- Set the color.
  color = color or {255, 255, 255}
  love.graphics.setColor(color)

  -- Convert coordinates.
  local win_w, win_h = win_size()

  -- We invert y here since love.graphics treats the top as y=0,
  -- and we treat the bottom as y=0.
  local x, y = (mid_x + 1) * win_w / 2, (1 - mid_y) * win_h / 2
  local w, h = w * win_w / 2, h * win_h / 2

  -- u is a unit vector pointing toward angle.
  local ux, uy  = math.cos(angle), math.sin(angle)
  local sw, sh  = 1, 1  -- The signs of the width/height to add.
  local pts = {}
  for i = 1, 4 do
    pts[#pts + 1] = (x) + (ux * sw * (w / 2)) - (uy * sh * (h / 2))
    pts[#pts + 1] = (y) + (uy * sw * (w / 2)) + (ux * sh * (h / 2))
    sw, sh = -sh, sw  -- Rotate the (sh, sw) corner by a right angle.
  end

  love.graphics.polygon('fill', pts)
end

function draw.str(s, x, y, limit, align)
  local win_w, win_h = win_size()
  x, y = (x + 1) * win_w / 2, (1 - y) * win_h / 2
  limit = limit * win_w / 2
  if align == 'right' then x = x - limit end
  love.graphics.printf(s, x, y, limit, align)
end

-- What is a circle in virtual coords could end up as an ellipse on the screen,
-- so this accepts a max_r which is the max radius in virtual coords.
-- This guarantees that the screen object is a circle.
-- Returns the effective radii in virtual coords.
function draw.circle(cx, cy, max_r, segments)
  local win_w, win_h = win_size()
  cx, cy = (cx + 1) * win_w / 2, (1 - cy) * win_h / 2
  local r_scale = min(win_w / 2, win_h / 2)
  local r = max_r * r_scale
  love.graphics.circle('line', cx, cy, r, segments)
  return r / (win_w / 2), r / (win_h / 2)
end

function draw.line(x1, y1, x2, y2)
  local win_w, win_h = win_size()
  x1, y1 = (x1 + 1) * win_w / 2, (1 - y1) * win_h / 2
  x2, y2 = (x2 + 1) * win_w / 2, (1 - y2) * win_h / 2
  love.graphics.line(x1, y1, x2, y2)
end


--------------------------------------------------------------------------------
-- LD32 specific functions.
--------------------------------------------------------------------------------

function draw.hero(x, y, w, h, label)
  w = w or 0.15
  h = h or 0.2

  -- dbg outline
  if dbg.do_draw_bounds then
    draw.rect(x, y, w, h, draw.white, 'line')
  end

  love.graphics.setColor({255, 255, 255})
  local r = min(w, h) * 0.15
  local cx, cy = x + w / 2, y + 0.8 * h
  local rx, ry = draw.circle(cx, cy, r, 20)
  local py = y + 0.3 * h
  draw.line(cx, cy - ry, cx, py)

  -- arm coords
  local ax1, ax2, ay = x + 0.3 * w, x + 0.7 * w, y + 0.5 * h
  draw.line(ax1, ay, ax2, ay)

  -- legs
  local leg_y = y + 0.1 * h
  draw.line(cx, py, ax1, leg_y)
  draw.line(cx, py, ax2, leg_y)

  -- label
  if label then
    love.graphics.setColor({0, 200, 200})
    draw.str(label, x, y + h, w, 'left')
  end
end


return draw

