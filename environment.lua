--[[
Settings and functions related to the window and border properties
'greenzone' refers to the area inside the borders
]]
local environment = {}

environment.window_properties     = {} -- 1 = 100% of default size (in conf.lua)
environment.border_properties     = {border_thickness = 10}
environment.greenzone             = {top    = 0 + environment.border_properties.border_thickness,
                                     bottom = 0,
                                     left   = 0 + environment.border_properties.border_thickness,
                                     right  = 0}

local window_width, window_height = love.window.getMode()
environment.window_properties.window_width = window_width
environment.window_properties.window_height = window_height

-- set greenzone variables
environment.greenzone.bottom = window_height - environment.border_properties.border_thickness
environment.greenzone.right  = window_width  - environment.border_properties.border_thickness

-- border options
environment.border_properties.border_start_coord = environment.border_properties.border_thickness / 2
environment.border_properties.border_width       = window_width  - environment.border_properties.border_thickness
environment.border_properties.border_height      = window_height - environment.border_properties.border_thickness

-- physical properties of the environment
function environment.build()
    environment.lowerBound = {}
    environment.lowerBound.body    = love.physics.newBody(world, window_width/2, window_height-(environment.border_properties.border_thickness/2), "static") -- x,y of the centroid of the body
    environment.lowerBound.shape   = love.physics.newRectangleShape(window_width,environment.border_properties.border_thickness) -- width, length
    environment.lowerBound.fixture = love.physics.newFixture(environment.lowerBound.body, environment.lowerBound.shape, 1) -- set fixture and give a friction value
    environment.lowerBound.fixture:setUserData("lower")  

    environment.upperBound = {}
    environment.upperBound.body    = love.physics.newBody(world, window_width/2, environment.border_properties.border_thickness/2, "static")
    environment.upperBound.shape   = love.physics.newRectangleShape(window_width, environment.border_properties.border_thickness)
    environment.upperBound.fixture = love.physics.newFixture(environment.upperBound.body, environment.upperBound.shape, 1)
    environment.upperBound.fixture:setUserData("upper")

    environment.leftBound = {}
    environment.leftBound.body    = love.physics.newBody(world, environment.border_properties.border_thickness/2, window_width/2, "static")
    environment.leftBound.shape   = love.physics.newRectangleShape(environment.border_properties.border_thickness, window_width)
    environment.leftBound.fixture = love.physics.newFixture(environment.leftBound.body, environment.leftBound.shape, 1)
    environment.leftBound.fixture:setUserData("left")

    environment.rightBound = {}
    environment.rightBound.body    = love.physics.newBody(world, window_width-(environment.border_properties.border_thickness/2), window_width/2, "static")
    environment.rightBound.shape   = love.physics.newRectangleShape(environment.border_properties.border_thickness, window_width)
    environment.rightBound.fixture = love.physics.newFixture(environment.rightBound.body, environment.rightBound.shape, 1)  
    environment.rightBound.fixture:setUserData("right")
end

return environment