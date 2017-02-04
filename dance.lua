--[[
Attributes and functions for a dance
]]
local stg = require "settings"

function create_dance(id, x, y, qual)
	local dance = {}

	dance.food_id = id
	dance.quality = qual
	dance.get_x = function() return x end
	dance.get_y = function() return y end
	dance.length = stg.base_dance_time * qual
	dance.radius = stg.food_radius

	return dance
end
