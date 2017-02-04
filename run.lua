love.math.setRandomSeed(os.time())
local gen = require "generate_values"
local stg = require "settings"
local env = require "environment" -- set window size, border and background properties
require "agent"
require "home"
require "food"
require "dance"

function run_load()
    love.physics.setMeter(64) --the height of a meter our worlds will be 64px
    world = love.physics.newWorld(0, 0, true) -- a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
    world:setCallbacks(begin_contact, end_contact, pre_solve, post_solve)
    
    env.build()
    home = create_home()
    pause = false

    -- create agents
    agents = {}
    add_agents(agents)

    -- create food
    foods = {}
    add_foods(foods)
    total_food = stg.number_food * stg.food_amount
    food_image = love.graphics.newImage("flower.png")

    -- TIMER = os.clock() -- only needed to set time limit for simulation
end

function add_agents(ags)
    local num_onlookers = stg.number_onlookers
    for i = 1, num_onlookers do
        local name = "o" .. i
        local a = create_agent(name, "onlooker", home)
        table.insert(ags, a)
        ags[name] = a
    end

    local num_scouts    = stg.number_scouts
    for i = 1, num_scouts do
        local name = "s" .. i
        local a = create_agent(name, "scout", home)
        table.insert(ags, a)
        ags[name] = a
    end

    local num_foragers  = stg.number_foragers
    assert(num_foragers == 0, "Foragers cannot be created at initialization.")
end

function add_foods(fds)
    local num_food = stg.number_food
    local food_locs = gen.some_food_locations(num_food)
    for i = 1, num_food do
        table.insert(fds, create_food(food_locs[i]))
    end
end

function run_update(dt)
    if not pause then
        world:update(dt) -- put the world into motion

        for i = 1, #agents do
            if agents[i].worker_type == "scout" then
                enact_scout_state(agents[i], foods, home)
                update_scout_state(agents[i], foods, home)
            elseif agents[i].worker_type == "forager" then
                enact_forager_state(agents[i], foods, home)
                update_forager_state(agents[i], foods, home)
            elseif agents[i].worker_type == "onlooker" then
                enact_onlooker_state(agents[i], foods, home)
                update_onlooker_state(agents[i], foods, home)
            end
        end
    end
    
    return home.amount == total_food
    -- return (os.clock() - TIMER) >= 60
end

function run_draw()
    love.graphics.setBackgroundColor(stg.background_colour)

    -- draw border
    love.graphics.setColor(stg.border_colour)
    love.graphics.setLineWidth(env.border_properties.border_thickness)
    love.graphics.rectangle("line", env.border_properties.border_start_coord, 
        env.border_properties.border_start_coord, env.border_properties.border_width, env.border_properties.border_height)

    -- draw home
    love.graphics.setColor(home.colour)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", home.get_x(), home.get_y(), home.radius, 6)

    -- draw food
    for i = 1, #foods do
        love.graphics.setColor(foods[i].colour)
        -- love.graphics.circle("fill", foods[i].get_x(), foods[i].get_y(), foods[i].radius)
        love.graphics.draw(food_image, foods[i].get_x()+foods[i].radius, foods[i].get_y()+foods[i].radius, foods[i].radius, 0.03,0.03)
    end

    -- draw agents
    for i = 1, #agents do
        love.graphics.setColor(agents[i].colour)
        love.graphics.circle("fill", agents[i].get_x(), agents[i].get_y(), agents[i].radius)
    end
end

-- beginContact gets called when two fixtures start overlapping (two objects collide).
-- move away from an object if collision occurs
function begin_contact(a, b, coll)
    local agent = agents[b:getUserData()]
    agent.angle = agent.angle - (math.pi + math.random())
end
 
-- endContact gets called when two fixtures stop overlapping (two objects disconnect).
function end_contact(a, b, coll)
end
 
-- preSolve is called just before a frame is resolved for a current collision
function pre_solve(a, b, coll)
end
 
-- postSolve is called just after a frame is resolved for a current collision.
function post_solve(a, b, coll, normalimpulse, tangentimpulse)
end