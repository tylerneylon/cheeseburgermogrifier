--[[ ld32/src/sounds.lua

--]]

local sounds = {}


--------------------------------------------------------------------------------
-- Initialization.
--------------------------------------------------------------------------------

local names = {
  'shoot', 'hero_hit', 'guard_hit', 'shot_wall',
  'walking', 'dialog1', 'dialog2', 'tasty',
  'villain', 'woohoo', 'died'
}

for _, name in pairs(names) do
  sounds[name] = love.audio.newSource('audio/' .. name .. '.wav', 'static')
end

sounds.intro = love.audio.newSource('audio/intro.mp3')
sounds.intro:setVolume(0.2)


--------------------------------------------------------------------------------
-- Return.
--------------------------------------------------------------------------------

return sounds

