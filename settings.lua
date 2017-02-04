--[[
Configuration settings for the run
]]
local colours = require("colours")
local settings = {}

-- environment settings
settings.agent_radius  = 2
settings.agent_speed   = 0.01
settings.agent_sight   = settings.agent_radius*2
settings.food_radius   = 10
settings.food_spacer   = settings.food_radius*2
settings.home_radius   = 20

-- run parameters
settings.number_onlookers = 10
settings.number_scouts    = 10
settings.number_foragers  = 0
settings.base_dance_time  = 8
settings.number_food      = 10
settings.food_amount      = 10

-- robustness settings
settings.failure_rate = 0

-- display settings
-- settings.background_colour = colours.light_grey
settings.background_colour = colours.pale_green
settings.border_colour     = colours.black
settings.home_colour       = colours.orange
settings.food_colour       = colours.dark_green

return settings
