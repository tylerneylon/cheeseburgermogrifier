--[[ ld32/src/walls.lua

Functions for working with walls.

--]]

require 'strict'  -- Enforce careful global variable usage.

local walls = {}


--------------------------------------------------------------------------------
-- Require modules.
--------------------------------------------------------------------------------

local draw     = require 'draw'


--------------------------------------------------------------------------------
-- Internal level data.
--------------------------------------------------------------------------------

local level = [[
111111111
1       1
1       1
1       1
111111111
]]

--------------------------------------------------------------------------------
-- Public functions.
--------------------------------------------------------------------------------

function walls.draw()
  local first_line = level:match('(.-)\n')
  local    grid_w = #first_line
  local _, grid_h = level:gsub('\n', '')  -- Count the number of lines.
  --print('grid_w =', grid_w)
  --print('grid_h =', grid_h)
  local w, h = 2 / grid_w, 2 / grid_h
  --print('w, h =', w, h)
  local x, y = -1, 1 - h
  for line in level:gmatch('(.-)\n') do
    for i = 1, #line do
      local c = line:sub(i, i)
      if c == '1' then
        --print(string.format('drawing: %10g, %10g, %10g, %10g', x, y, w, h))
        draw.rect(x, y, w, h)
      end
      x = x + w
    end
    x = -1
    y = y - h
  end
end


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return walls
