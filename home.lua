--[[
Attributes and functions for home
]]
local greenzone = require("environment").greenzone
local stg       = require "settings"

function create_home()
	local home = {}

	home.radius  = stg.home_radius
	home.amount  = 0                -- amount of food in home
	home.colour  = stg.home_colour
	home.dance_floor  = {}

	local hx, hy = (greenzone.left + greenzone.right)/2, (greenzone.bottom + greenzone.top)/2 -- center of window

	home.get_x = function() return hx end
	home.get_y = function() return hy end
	home.has_info = function() -- dance floor dynamically changes as bees enter and leave
						for k,v in pairs(home.dance_floor) do
							return true
						end
						return false
					end

	return home
end
