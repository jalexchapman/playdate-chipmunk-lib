import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'


local gfx = playdate.graphics

gfx.setColor(gfx.kColorBlack)

local world_setup = false
local space = nil

-- placeholder proof of life
function playdate.update() 
    if not world_setup then
        setup()
    end
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)
    space:step(0.02)
    drawCircles()
    playdate.drawFPS(0,0)
end

space = {}
staticBody = {}
circleShapes = {}
circleBodies = {}
wallSegments = {}

function addRandomCircle()
    local radius = math.random(2, 10)
    local piDensity = 0.01
    local mass = piDensity * radius^2
    local friction = 0.3
    local elasticity = 0.5
    local moment = chipmunk.momentForCircle(mass, radius, 0, 0, 0)
    local body = chipmunk.body.new(mass, moment)
    print body:getMass()
    print body:getMoment()
    local shape = chipmunk.shape.newCircle(body, radius, 0, 0)
    body:setPosition(math.random(radius + 1, 399 - radius), math.random(radius + 1, 239 - radius))
    shape:setFriction(friction)
    shape:setElasticity(elasticity)
    space:addBody(body)
    space:addShape(shape)
    table.insert(circleBodies, body)
    table.insert(circleShapes, shape)
end

function drawCircles()
    for i, shape in ipairs(circleShapes) do
        local r = circleShapes[i]:getCircleRadius()
        local x, y = circleBodies[i]:getPosition()
        local angle = circleBodies[i]:getAngle()
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(x, y, r)
        gfx.setColor(gfx.kColorWhite)
        local xOff = math.cos(angle) * r
        local yOff = math.sin(angle) * r
        gfx.drawLine(x + xOff, y + yOff, x - xOff, y - yOff)
    end
end

function setup()
    playdate.display.setRefreshRate(50)
    space = chipmunk.space.new()
    space:setDamping(1.0)
    space:setGravity(0, 400.0)
    staticBody = space:getStaticBody()
    
    wallSegments = {
        chipmunk.shape.newSegment(staticBody,0,0,400,0),
        chipmunk.shape.newSegment(staticBody,0,240,400,240),
        chipmunk.shape.newSegment(staticBody,0,0,0,240),
        chipmunk.shape.newSegment(staticBody,400,0,400,240)
    }
    
    for _, segment in ipairs(wallSegments) do
        segment:setFriction(0.3)
        segment:setElasticity(0.5)
        space:addShape(segment)
    end
    for i=1, 3 do
        addRandomCircle()
    end
    drawCircles()

    world_setup = true
end