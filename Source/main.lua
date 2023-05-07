import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'


local gfx = playdate.graphics

gfx.setColor(gfx.kColorBlack)

local world_setup = false
local space = nil

kGravityMagnitude=6778

--kGravityMagnitude = 66778 -- 9.8 m/s^2, 173 ppi = 6811 px/m
gravity = {x=0, y=kGravityMagnitude, z=0}
space = {}
staticBody = {}
circleShapes = {}
wallSegments = {}
local lastPhysTime = 0
local lastGrafTime = 0

function updateGravity()
    x, y, z = playdate.readAccelerometer()
    gravity.x = x * kGravityMagnitude
    gravity.y = y * kGravityMagnitude
    gravity.z = y * kGravityMagnitude
    space:setGravity(gravity.x, gravity.y)
end

function addRandomCircle()
    local radius = math.random(5, 30)
    local piDensity = 0.01
    local mass = piDensity * radius^2
    local friction = 0.3
    local elasticity = 0.5
    local moment = chipmunk.momentForCircle(mass, radius, 0, 0, 0)
    --print(space)
    --local body = chipmunk.body.new(mass, moment)
    local body = chipmunk.body.newDynamic(mass, moment)
    --print(body)
    local shape = chipmunk.shape.newCircle(body, radius, 0, 0)
    --print(shape:getBody())
    --print(shape)
    body:setPosition(math.random(radius + 1, 399 - radius), math.random(radius + 1, 239 - radius))
    shape:setFriction(friction)
    shape:setElasticity(elasticity)
    space:addBody(body)
    space:addShape(shape)
    table.insert(circleShapes, shape)
end

function newPeg(r, x, y, parentSpace)
    local shape = chipmunk.shape.newCircle(parentSpace:getStaticBody(), r, x, y)
    shape:setFriction(0.6)
    shape:setElasticity(0.7)
    parentSpace:addShape(shape)
    return shape
end

function addPegs()
    local radius = 3.0
    for i=80,320,160 do
        for j =80,160,80 do
            table.insert(circleShapes, newPeg(radius, i, j, space))
        end
        for k=40,200,80 do
            table.insert(circleShapes, newPeg(radius, i+80, k, space))
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
    space = chipmunk.space.new()
    space:setDamping(1.0)
    space:setGravity(0, 400.0)
    staticBody = space:getStaticBody()
    
    wallSegments = {
        chipmunk.shape.newSegment(staticBody,0,0,400,0,2),
        chipmunk.shape.newSegment(staticBody,0,240,400,240,2),
        chipmunk.shape.newSegment(staticBody,0,0,0,240,2),
        chipmunk.shape.newSegment(staticBody,400,0,400,240,2)
    }
    
    for _, segment in ipairs(wallSegments) do
        segment:setFriction(0.3)
        segment:setElasticity(0.5)
        space:addShape(segment)
    end
    for i=1,15 do
        addRandomCircle()
    end
    addPegs()
    drawCircles()
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
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)
    updateGravity()
    space:step(dt)
    drawCircles()
    lastPhysTime = now
    lastGrafTime = now
    playdate.drawFPS(0,0)
end