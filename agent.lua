local gen = require "generate_values"
local stg = require "settings"
require "dance"

function create_agent(n, work_type, home)
    local agent = {}

    -- initial settings
    agent.name = n
    agent.colour = gen.random_colour()
    agent.radius = stg.agent_radius
    agent.sight  = stg.agent_sight
    agent.angle  = gen.random_angle_rads()
    agent.speed  = stg.agent_speed
    agent.energy = 0

    -- state variables
    agent.worker_type  = work_type
    if agent.worker_type == "scout" then 
        agent.state = "wander"
    elseif agent.worker_type == "onlooker" then
        agent.state = "look"
    elseif agent.worker_type == "forager" then
        agent.state = "move_to_food"
    end

    agent.near_home    = false -- at home
    agent.near_food    = false -- at food source
    agent.nearest_food = 1     -- index of food source found
    agent.food_held    = 0

    -- onlooker info
    agent.interested = false  -- sees a dance on the dance floor
    agent.site = nil          -- saw a dance, knows a site of food

    -- scout info
    agent.has_info = false    -- found a site of food
    agent.dance = nil         -- has created a dance for the site found
    agent.is_dancing = false  -- is currently dancing at home
    agent.dance_timer = 0     -- the time the dancing started

    -- forager info
    agent.near_site = false   -- near the site of reported food
  
    -- physical attributes
    local pos = {} -- starting position of agent
    if agent.worker_type == "scout" then
        pos = gen.random_legal_position(agent.radius)
    else
        pos.x, pos.y = home.get_x(), home.get_y()
    end
    agent.body    = love.physics.newBody(world, pos.x, pos.y, "dynamic")
    agent.shape   = love.physics.newCircleShape(agent.radius)
    agent.fixture = love.physics.newFixture(agent.body, agent.shape, 1)
    agent.body:setAngle(agent.angle)
    agent.fixture:setUserData(n)
    agent.body:setLinearDamping(0.9)

    agent.get_x = function() return agent.body:getX() end
    agent.get_y = function() return agent.body:getY() end

    return agent
end

--[[
Begin general functions
]]
-- check if agent is intersecting an object
function ao_intersect(agent, ob, use_sense)
    local r1 = use_sense and agent.sight or agent.radius
    local r2 = ob.radius
    
    local x1, x2 = agent.get_x(), ob.get_x()
    local y1, y2 = agent.get_y(), ob.get_y()
    
    local d = ((x2-x1)^2+(y2-y1)^2)^0.5 -- distance formula
    return d < (r1 + r2)
end

-- move agent towards object
function ao_move(agent, ob)
    local start_X, start_Y, end_X, end_Y = agent.get_x(), agent.get_y(), ob.get_x(), ob.get_y()
    
    local diff = math.atan2(end_Y - start_Y, end_X - start_X)
    agent.angle = diff
    agent.body:setAngle(diff)
    agent.body:applyLinearImpulse(agent.body:getWorldVector(agent.speed, 0))
    agent.energy = agent.energy + 1
    
    return agent
end

-- the agent body is intersecting home
function sense_home(agent, home)
    if ao_intersect(agent, home) then
        agent.near_home = true
    else
        agent.near_home = false
    end
end
--[[
End general functions
]]

--[[
Begin onlooker behaviours
]]
-- check if there are bees dancing
function look(agent, home)
    if home.has_info() then
        agent.interested = true
    else
        agent.interested = false
    end
end

-- each dance seen is ranked by quality, higher quality dances are 
-- selected with higher probability 
function consider(agent, home)
    local best_quality = -1
    local best = nil

    -- sort the dances by quality
    local r_dance = {}
    for k,v in pairs(home.dance_floor) do
        table.insert(r_dance, v)
    end
    table.sort(r_dance, function(a,b) return a.quality > b.quality end) -- first is best
    
    local default = r_dance[1]

    -- roulette wheel selection
    local function sum(n) return (n*(n+1))/2 end
    local sz = sum(#r_dance)
    local counter = 0
    local chosen = default
    for i = #r_dance, 1, -1 do
        local p = i/sz -- probability of being chosen
        local r = math.random()
        if r > counter and r < (counter + p) then
            chosen = (#r_dance - i) + 1
            break
        else
            counter = counter + p
        end
    end

    agent.interested = false
    agent.site = r_dance[chosen]
end

function forage(agent)
    agent.worker_type = "forager"
    agent.state = "move_to_food"
end
--[[
End onlooker behaviours
]]

--[[
Begin scout behaviours
]]
-- walk in random direction
function wander(agent)
    agent.body:setAngle(agent.angle)
    agent.body:applyLinearImpulse(agent.body:getWorldVector(agent.speed, 0))
    agent.energy = agent.energy + 1
    
    return agent
end

-- the agent body is intersecting food
function sense_food(agent, foods)
    for i = 1, #foods do
        if ao_intersect(agent, foods[i]) then
            agent.near_food = true
            agent.nearest_food = i
            return
        end
    end
    agent.near_food = false
end

-- assess the quality of a food source by amount and distance
function get_quality(food, home)
    local x1, x2 = food.get_x(), home.get_x()
    local y1, y2 = food.get_y(), home.get_y()
    local fd = ((x2-x1)^2+(y2-y1)^2)^0.5 -- distance between food and home
    local hd = ((x2-0 )^2+(y2-0 )^2)^0.5 -- distance from home to furthest point (for scaling)

    local function map_range(x, from_min, from_max, to_min, to_max)
        return (x - from_min) * (to_max - to_min) / (from_max - from_min) + to_min
    end

    local scaled_distance = map_range(fd, 0, hd, 0, 1)
    local scaled_food     = map_range(food.amount, 0, stg.food_amount, 1, 2)

    return scaled_food - scaled_distance
end

-- create a dance after seeing a food source
function investigate(agent, foods, home)
    local fx, fy = foods[agent.nearest_food].get_x(), foods[agent.nearest_food].get_y()
    local q = get_quality(foods[agent.nearest_food], home)

    agent.has_info = true
    agent.dance = create_dance(agent.nearest_food, fx, fy, q)
end

-- inform home of dance for an amount of time 
function dance(agent, home)
    if not agent.is_dancing then
        local t = os.clock()
        agent.is_dancing = true
        agent.dance_timer = t
        home.dance_floor[agent.name] = agent.dance
    else
        if (os.clock() - agent.dance_timer) > agent.dance.length then
            agent.has_info = false
            agent.dance = nil
            agent.is_dancing = false
            agent.dance_timer = 0
            home.dance_floor[agent.name] = nil
        end
    end
end
--[[
End scout behaviours
]]

--[[
Begin Forager behaviours
]]
function move_to_food(agent)
    ao_move(agent, agent.site)
end

-- agent is intersecting reported food site
function sense_site(agent)
    if ao_intersect(agent, agent.site) then
        agent.near_site = true
    else
        agent.near_site = false
    end
end

-- agent looks for food at reported food site
function sense_source(agent, foods)
    for i = 1, #foods do
        if ao_intersect(agent, foods[i]) then
            agent.near_food = true
            agent.nearest_food = i
            break
        else
            agent.near_food = false
        end
    end
end

-- remove food from site
function gather(agent, foods)
    agent.near_food = false
    agent.near_site = false
    if foods[agent.nearest_food] and foods[agent.nearest_food].amount > 0 then
        agent.food_held = agent.food_held + 1
        foods[agent.nearest_food].amount = foods[agent.nearest_food].amount - 1
        if foods[agent.nearest_food].amount == 0 then
            table.remove(foods, agent.nearest_food)
        end
    end
end

-- add food to home
function dump_food(agent, home)
    agent.near_home = false
    if agent.food_held > 0 then
        agent.food_held = agent.food_held - 1
        home.amount = home.amount + 1
    end
end

function onlook(agent)
    agent.worker_type = "onlooker"
    agent.state = "move_home"
end
--[[
End forager behaviours
]]

--[[
Begin FSMs
]]
function update_onlooker_state(agent, foods, home)
    if agent.state == "look" and not agent.near_home then
        agent.state = "move_home"
    elseif agent.state == "move_home" then
        agent.state = "sense_home"
    elseif agent.state == "sense_home" and not agent.near_home then
        agent.state = "move_home"
    elseif agent.state == "sense_home" then
        agent.state = "look"
    elseif agent.state == "look" and agent.interested then
        agent.state = "consider"
    elseif agent.state == "look" then
        agent.state = "sense_home"
    elseif agent.state == "consider" and agent.site then
        agent.state = "forage"
    elseif agent.state == "consider" and not agent.site then
        agent.state = "look"
    end
end

function enact_onlooker_state(agent, foods, home)
    if agent.state == "look" then
        look(agent, home)
    elseif agent.state == "consider" then
        consider(agent, home)
    elseif agent.state == "forage" then
        forage(agent)
    elseif agent.state == "move_home" then
        ao_move(agent, home)
    elseif agent.state == "sense_home" then
        sense_home(agent, home)
    end
end

function update_scout_state(agent, foods, home)
    if agent.state == "wander" then
        agent.state = "sense_food"
    elseif agent.state == "sense_food" and not agent.near_food then
        agent.state = "wander"
    elseif agent.state == "sense_food" and agent.near_food then
        agent.state = "investigate"
    elseif agent.state == "investigate" then
        agent.state = "move_home"
    elseif agent.state == "move_home" then
        agent.state = "sense_home"
    elseif agent.state == "sense_home" and not agent.near_home then
        agent.state = "move_home"
    elseif agent.state == "sense_home" and agent.near_home then
        agent.state = "dance"
    elseif agent.state == "dance" and agent.dance_timer <= 0 then
        agent.state = "wander"
    elseif agent.state == "dance" then
        agent.state = "move_home"
    end
end

function enact_scout_state(agent, foods, home)
    if agent.state == "wander" then
        wander(agent)
    elseif agent.state == "sense_food" then
        sense_food(agent, foods)
    elseif agent.state == "move_home" then
        ao_move(agent, home)
    elseif agent.state == "sense_home" then
        sense_home(agent, home)
    elseif agent.state == "investigate" then
        investigate(agent, foods, home)
    elseif agent.state == "inform" then
        inform(agent, home)
    elseif agent.state == "dance" then
        dance(agent, home)
    end
end

function update_forager_state(agent, foods, home)
    if agent.state == "move_to_food" then
        agent.state = "sense_site"
    elseif agent.state == "sense_site" and not agent.near_site then
        agent.state = "move_to_food"
    elseif agent.state == "sense_site" and agent.near_site then
        agent.state = "sense_source"
    elseif agent.state == "sense_source" and agent.near_food then
        agent.state = "gather"
    elseif agent.state == "sense_source" and not agent.near_food then
        agent.state = "onlook"
    elseif agent.state == "gather" then -- and agent.food_held == 1 or foods[agent.site.food_id].amount == 0 then
        agent.state = "move_home"
    elseif agent.state == "move_home" then
        agent.state = "sense_home"
    elseif agent.state == "sense_home" and not agent.near_home then
        agent.state = "move_home"
    elseif agent.state == "sense_home" and agent.near_home then
        agent.state = "dump"
    elseif agent.state == "dump" then
        agent.state = "onlook"
    end
end

function enact_forager_state(agent, foods, home)
    if agent.state == "move_to_food" then
        move_to_food(agent)
    elseif agent.state == "sense_site" then
        sense_site(agent)
    elseif agent.state == "gather" then
        gather(agent, foods)
    elseif agent.state == "move_home" then
        ao_move(agent, home)
    elseif agent.state == "sense_home" then
        sense_home(agent, home)
    elseif agent.state == "dump" then
        dump_food(agent, home)
    elseif agent.state == "onlook" then
        onlook(agent)
    elseif agent.state == "sense_source" then
        sense_source(agent, foods)
    end
end
--[[
End FSMs
]]
