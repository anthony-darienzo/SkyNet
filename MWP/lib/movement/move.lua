local module = loadfile('/MWP/lib/module.lua')()
local gps2 = module.require('/MWP/lib/movement/gps2.lua')

-- Standard Vectors
local I = vector.new(1,0,0)
local J = vector.new(0,1,0)
local K = vector.new(0,0,1)


------------------------------------------------------
----------------- HELPER FUNCTIONS -------------------

-- In order to deal with event handling higher up, we need to write helper functions
--      that yield the current coroutine before moving each block. Essentially, we are
--      creating a parallel system where the robot checks auxiliary functions after
--      moving a single block. That way, we can deal with event interrupts, etc..

forward = function ()
    --coroutine.yield('sufficient_fuel')
    return turtle.forward()
end

up = function ()
    --coroutine.yield('sufficient_fuel')
    return turtle.up()
end

down = function ()
    --coroutine.yield('sufficient_fuel')
    return turtle.down()
end



------------------------------------------------------
------------------ GOTO LOCATION ---------------------

-- Travel down trajectory vector
local function traverseTrajectory(trajectory, breakBlocks)

    local dx = trajectory.x
    local dy = trajectory.y
    local dz = trajectory.z

    local sign_x = dx/math.abs(dx)
    local sign_y = dy/math.abs(dy)
    local sign_z = dz/math.abs(dz)

    -- Move in x first
    if (dx ~= 0) then
        gps2.orientTurtle(I:mul(sign_x), true)
        for i = 1,math.abs(dx) do
            if not forward() then
                if breakBlocks then
                    turtle.dig()
                    forward()
                end
            end
        end
    end

    -- Move in z now
    if (dz ~= 0) then
        gps2.orientTurtle(K:mul(sign_z), true)
        for i = 1,math.abs(dz) do
            if not forward() then
                if breakBlocks then
                    turtle.dig()
                    forward()
                end
            end
        end
    end

    -- Move in y
    if (sign_y) > 0 then
        for i = 1,math.abs(dy) do
            if not up() then
                if breakBlocks then
                    turtle.digUp()
                    up()
                end
            end
        end
    elseif (sign_y) < 0 then
        for i = 1,math.abs(dy) do
            if not down() then
                if breakBlocks then
                    turtle.digDown()
                    down()
                end
            end
        end
    end
end

-- Go to location (takes a 3 vector for destination). Tolerance is the
-- maximum distance from destination allowed
function goTo(destination, _breakBlocks, _tolerance)


    local breakBlocks = _breakBlocks or false
    local tolerance = _tolerance or 1

    repeat
        local err, trajectory = gps2.getTrajectory(destination)

        if not err then
            traverseTrajectory(trajectory, breakBlocks)
        else
            print('Failed to get trajectory, aborting goTo to '.. trajectory:tostring())
            break
        end

    until trajectory:length() < tolerance
    -- FIX ME until trajectory:round():length() < tolerance
end

------------------------------------------------------
-------------- ENVIROMENTAL ORIENTATION --------------

function orientChunk()
    local err, loc = gps2.getLocation()
    if not err then
        goTo(vector.new(loc.x - loc.x % 16, -- 16 BLOCKS IN A CHUNK
                        loc.y,
                        loc.z - loc.z % 16), true)
        gps2.orientTurtle(I, true)
        return loc.y
    else
        print("Error in Location")
    end
end
