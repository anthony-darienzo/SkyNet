local direction = 0

function cornerCheck()
    if (direction == 0) then
        turtle.turnRight()
        if (not turtle.detect()) then
            direction = 1
        end
        turtle.forward()
        turtle.turnRight()
    else
        turtle.turnLeft()
        if (not turtle.detect()) then
            direction = 0
        end
        turtle.forward()
        turtle.turnLeft()
    end
end

function sortSlots()
    for i = 1, 3 do
        for j = 4, 16 do
            turtle.select(j)
            if turtle.compareTo(i) then
                turtle.transferTo(i)
            end
        end
    end
end

function totalRefuel()
    for i = 1, 16 do
        turtle.select(i)
        local fuel = turtle.getItemDetail()
        if fuel then
            if (fuel.name == "minecraft:charcoal" or fuel.name == "minecraft:coal") then
                turtle.select(1)
                turtle.refuel(turtle.getItemCount(1)-1) -- leave something in slot
            end
        end
    end
end

function refuelFurnance()
    turtle.select(1)
    turtle.suckUp() -- pull out produced charcoal
    turtle.refuel(13) -- ensure we have a baseline amount of fuel
    turtle.back()
    turtle.up()
    turtle.suck()
    turtle.up()
    turtle.forward()
    turtle.select(3)
    local item = turtle.getItemDetail()
    if item then
        if (item.name == "minecraft:log") then
            turtle.dropDown(turtle.getItemCount(3)-1) -- leave one to reserve slot
        end
    end
    turtle.back()
    turtle.down()
    turtle.down()
    turtle.forward()
    turtle.select(1)
    local item = turtle.getItemDetail()
    if item then
        if (item.name == "minecraft:charcoal" or item.name == "minecraft:coal") then
            if (turtle.getItemCount(1) > 8) then
                turtle.dropUp(8) -- all that is needed
            end
        end
    end
    totalRefuel() -- use rest of fuel
    turtle.forward()
end

function cutTree()
    turtle.dig()
    turtle.forward()
    turtle.digUp()
    turtle.up()
    turtle.select(2)
    local item = turtle.getItemDetail()
    if item then
        if (item.name == "minecraft:sapling" and turtle.getItemCount(2) > 1) then
            turtle.placeDown()
        end
    end
    while(turtle.detectUp()) do
        turtle.digUp()
        turtle.up()
    end
    while(not turtle.detectDown()) do
        turtle.down()
    end
    turtle.forward()
    turtle.down()
end

function evadeSaplings()
    turtle.up() -- Please DO NOT put saplings on edge of farm
    turtle.forward()
    turtle.forward()
    turtle.down()
end

-- ====== BEGIN MAIN CODE ======
totalRefuel()

while true do

    print(turtle.getFuelLevel())

    local success, data = turtle.inspectUp()
    if success then
        if (data.name == "minecraft:furnace" or data.name == "minecraft:lit_furnace") then
            sortSlots()
            refuelFurnace()
        end
    end

    local success, data = turtle.inspect()
    if (not success) then
        turtle.suck()
        turtle.forward()
    elseif (data.name == "minecraft:log") then
        cutTree()
    elseif (data.name == "minecraft:sapling") then
        evadeSaplings()
    elseif (data.name == "minecraft:chest") then
        for i = 4, 16 do
            turtle.select(i)
            turtle.drop()
        end
        cornerCheck()
    else
        cornerCheck()
    end
end