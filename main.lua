--[[
This file sets up the simulation to run N times and logs statistics to a file
]]

require "run"
local stg = require "settings"

function tic()
    _time = os.clock()
end

function toc()
    return string.format("%.6f", os.clock() - _time)
end

function open_log()
    _log = assert(io.open("log.txt", "w"))
end

function close_log()
    _log:flush()
    _log:close()
end

function save(str)
    _log:write(str .. "\n")
    _log:flush()  
end

local number_runs = 10
local run_number = 1
local updates = 0

open_log()
save("Log opened at:" .. os.date("%c"))
save("Settings:")
for k, v in pairs(stg) do
    save(k .. ":" .. tostring(v))
end
save("Window size X: " .. love.graphics.getWidth())
save("Window size Y: " .. love.graphics.getHeight())

function love.load()
    print("Run number: " .. run_number)
    save("Log run " .. run_number .. " starting at: " .. os.date("%c"))
    run_load()
    tic()
end

function love.update(dt)
    updates = updates + 1
    if run_update(dt) then
        save("time_taken: " .. toc())
        save("energy_used: " .. get_energy_use())
        save("updates_used: " .. updates)
        save("food_gathered: " .. home.amount)
        -- save("agents_killed: " .. killed)
        save("Log ending at:" .. os.date("%c"))
        if run_number >= number_runs then
            close_log()
            love.event.quit(0)
        end
        updates = 0
        run_number = run_number + 1
        love.load()
    end
end

function get_energy_use()
    local en = 0
    for k,v in ipairs(agents) do
        en = en + v.energy
    end

    return en
end

function love.draw()
    run_draw()
end

function love.keypressed(key)
    if key == "r" then
        run_load()
    elseif key == "p" then
        pause = not pause
    end
end