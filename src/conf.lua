--[[ ld32/src/conf.lua

Basic Love game configuration.

--]]

function love.conf(t)
  t.title    = 'ld32-gaarlicbread'
  t.identity = 'ld32-gaarlicbread'
  -- This weird window size is to make my sprites integer-sized.
  -- I chose the grid size without thinking about even pixel division by accdient.
  t.window.width  = 1022
  t.window.height = 762
end
