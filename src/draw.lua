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
-- General drawing functions.
--------------------------------------------------------------------------------

-- x, y is the lower-left corner of the rectangle.
function draw.rect(x, y, w, h, color)
  -- Set the color.
  color = color or {255, 255, 255}
  love.graphics.setColor(color)

  -- Convert coordinates.
  local win_w, win_h = love.graphics.getDimensions()
  -- We invert y here since love.graphics treats the top as y=0,
  -- and we treat the bottom as y=0.
  x, y = (x + 1) * win_w / 2, (1 - y) * win_h / 2
  w, h = w * win_w / 2, h * win_h / 2

  -- Shift y since love.graphics draws from the upper-left corner.
  y = y - h

  -- Draw the rectangle.
  love.graphics.rectangle('fill', x, y, w, h)
end

function draw.rect_w_mid_pt(mid_x, mid_y, w, h, color)
  -- Set (x, y) to the lower-left corner of the rectangle.
  local x = mid_x - w / 2
  local y = mid_y - h / 2
  draw.rect(x, y, w, h, color)
end

function draw.rotated_rect(mid_x, mid_y, w, h, color, angle)
  -- Set the color.
  color = color or {255, 255, 255}
  love.graphics.setColor(color)

  -- Convert coordinates.
  local win_w, win_h = love.graphics.getDimensions()

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
  local win_w, win_h = love.graphics.getDimensions()
  x, y = (x + 1) * win_w / 2, (y + 1) * win_h / 2
  limit = limit * win_w / 2

  if align == 'right' then x = x - limit end

  love.graphics.printf(s, x, y, limit, align)
end

return draw

