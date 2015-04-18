--[[ ld32/src/dbg.lua

Debug parameters.

This file exists so we can easily turn on and off
certain features useful for debugging.

--]]

require 'strict'  -- Enforce careful global variable usage.


local dbg = {}

-- If dbg.cycles_per_frame = 1, then it's full speed (normal operation), if
-- it's = 2, then we're at half speed, etc.
dbg.cycles_per_frame = 1
dbg.frame_offset = 0

return dbg
