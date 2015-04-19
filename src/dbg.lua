--[[ ld32/src/dbg.lua

Debug parameters.

This file exists so we can easily turn on and off
certain features useful for debugging.

--]]

require 'strict'  -- Enforce careful global variable usage.


local dbg = {}

dbg.max_health  = 3
dbg.hero_speed  = 0.05
dbg.baddy_speed = 1.0

dbg.shot_len    = 0.5
dbg.shot_speed  = 5

dbg.baddy_fire_interval = 1

dbg.status_height = 30

dbg.do_draw_bounds    = true
dbg.do_draw_vis_lines = true

-- If dbg.cycles_per_frame = 1, then it's full speed (normal operation), if
-- it's = 2, then we're at half speed, etc.
dbg.cycles_per_frame = 1
dbg.frame_offset = 0

return dbg
