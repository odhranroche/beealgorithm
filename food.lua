--[[
Attributes and functions for a food source
]]
local stg = require "settings"
local gen = require "generate_values"

function create_food(location)
    local food     = {}

    food.radius    = stg.food_radius
    food.amount    = stg.food_amount
    food.colour    = gen.random_colour()--stg.food_colour

    local fx, fy = location[1], location[2]
    food.get_x = function() return fx end
    food.get_y = function() return fy end

    return food
end