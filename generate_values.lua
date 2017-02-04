--[[
Any random values that need to be generated are stored in functions here
]]
local greenzone = require("environment").greenzone
local stg       = require "settings"

local gen = {}

function gen.random_colour()
    return {math.random(255), math.random(255), math.random(255)}
end

-- a position inside the environment border
function gen.random_legal_position(radius)
    return {
        x = math.random(greenzone.left + radius, greenzone.right  - radius),
        y = math.random(greenzone.top  + radius, greenzone.bottom - radius)
    }
end

function gen.random_velocity(speed)
    return {
        x = math.random()*(math.random() > 0.5 and 1 or -1) * speed,
        y = math.random()*(math.random() > 0.5 and 1 or -1) * speed
    }
end

function gen.random_angle_rads()
    return math.random(-2*math.pi, 2*math.pi)
end

function gen.all_food_locations()
    local spacer = stg.food_spacer -- distance between food placements
    local locs = {}
    for i = greenzone.left + spacer/2, greenzone.right - spacer/2, spacer do
        for j = greenzone.top + spacer/2, greenzone.bottom - spacer/2, spacer do
            table.insert(locs, {i, j})
        end
    end

    return locs
end

function gen.some_food_locations(num_food)
    local spacer = stg.food_spacer -- distance between food placements
    local locs = {}
    local all = gen.all_food_locations()
    for i = 1, num_food do
        locs[i] = table.remove(all, math.random(1, #all))
    end

    return locs
end

return gen
