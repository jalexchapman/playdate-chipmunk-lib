import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'
import "disc"
import "world"

local gfx = playdate.graphics
gfx.setColor(gfx.kColorBlack)

local world_setup = false

kGravityMagnitude=6778

--kGravityMagnitude = 66778 -- 9.8 m/s^2, 173 ppi = 6811 px/m
gravity = {x=0, y=kGravityMagnitude, z=0}
circleShapes = {}
wallSegments = {}
allConstraints = {}
local lastPhysTime = 0
local lastGrafTime = 0

function updateGravity()
    x, y, z = playdate.readAccelerometer()
    gravity.x = x * kGravityMagnitude
    gravity.y = y * kGravityMagnitude
    gravity.z = y * kGravityMagnitude
    World.space:setGravity(gravity.x, gravity.y)
end

function addRandomCircle()
    local radius = math.random(5, 30)
    local density = 0.003
    local friction = 0.3
    local elasticity = 0.5
    local x = math.random(radius + 1, 399 - radius)
    local y = math.random(radius + 1, 239 - radius)

    local newDisc = Disc(x, y, radius, density, friction, elasticity)
    if (newDisc ~= nil) then
        printTable(newDisc)
        newDisc:addSprite()
    else
        print("newDisc seems to be nil?")
    end
end

function newPeg(r, x, y)
    local shape = chipmunk.shape.newCircle(World.staticBody, r, x, y)
    shape:setFriction(0.6)
    shape:setElasticity(0.7)    
    World.space:addShape(shape)
    local body = World.staticBody
    return shape
end

function addPegs()
    local radius = 3.0
    for i=80,320,160 do
        for j =80,160,80 do
            table.insert(circleShapes, newPeg(radius, i, j))
        end
        for k=40,200,80 do
            table.insert(circleShapes, newPeg(radius, i+80, k))
        end
    end
end

function drawCircles()
    for i, shape in ipairs(circleShapes) do
        local body = shape:getBody()
        local r = shape:getCircleRadius()
        local x, y = body:getPosition()
        local a = body:getAngle()
        local xO, yO = shape:getCircleOffset()
        if xO then
            x = x + xO
        end
        if yO then
            y = y + yO
        end
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorWhite)
        local xEdge = math.cos(a) * r
        local yEdge = math.sin(a) * r
        gfx.drawLine(x + xEdge, y + yEdge, x - xEdge, y - yEdge)
    end
end

function setup()
    playdate.startAccelerometer()
    playdate.display.setRefreshRate(50)
    World:setup()
    
    wallSegments = {
        chipmunk.shape.newSegment(World.staticBody,-20,-20,420,-20,20),
        chipmunk.shape.newSegment(World.staticBody,-20,260,420,260,20),
        chipmunk.shape.newSegment(World.staticBody,-20,-20,-20,260,20),
        chipmunk.shape.newSegment(World.staticBody,420,-20,420,260,20)
    }
    
    for _, segment in ipairs(wallSegments) do
        segment:setFriction(0.3)
        segment:setElasticity(0.5)
        printTable(World.space)
        World.space:addShape(segment)
    end
    for i=1,10 do
        addRandomCircle()
    end
    --addPegs()
    --drawCircles()
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)
    lastPhysTime = playdate.getCurrentTimeMilliseconds()
    lastGrafTime = lastPhysTime
    world_setup = true
end

function playdate.update() 
    if not world_setup then
        setup()
    end
    local now = playdate.getCurrentTimeMilliseconds()
    local dt = (now - lastPhysTime)/1000
    if dt > 100 then dt = 100 end -- just do slowdown at 10fps or slower to avoid glitching
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240) --FIXME - failing to update without this right now
    updateGravity()
    World.space:step(dt)
    gfx.sprite.update()
    --drawCircles()
    lastPhysTime = now
    lastGrafTime = now
    playdate.drawFPS(0,0)
end