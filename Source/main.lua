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
        -- printTable(newDisc)
        newDisc:addSprite()
    else
        print("newDisc seems to be nil?")
    end
    return newDisc
end

function addPeg(r, x, y)
    local friction = 0.6
    local elasticity = 0.7
    local peg = Circle(World.staticBody, x, y, r, friction, elasticity)
    print("Adding peg size " .. r .. " at " .. x .."," .. y)
    peg:addSprite()
    return peg
end

function addPegs()
    local radius = 3.0
    for i=80,320,160 do
        for j =80,160,80 do
            addPeg(radius, i, j)
        end
        for k=40,200,80 do
            addPeg(radius, i+80, k)
        end
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
    addPegs()
    for i=1,10 do
       addRandomCircle()
    end
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)
    lastPhysTime = playdate.getCurrentTimeMilliseconds()
    lastGrafTime = lastPhysTime
    world_setup = true
end

local perfStats = {samples=0, dtMax=0, dtMin = math.huge, dtAvg = 0}

local function updatePerf(dt)
    local agg = perfStats.samples * perfStats.dtAvg
    perfStats.samples = perfStats.samples + 1
    agg = agg + dt
    perfStats.dtAvg = agg/perfStats.samples
    if 0 < dt and dt < perfStats.dtMin then perfStats.dtMin = dt end
    if dt > perfStats.dtMax then perfStats.dtMax = dt end
end

local function drawPerf(x, y)
    gfx.drawText(string.format( -- draw perf
    "min dt: %e\nmax dt: %e\nmean dt: %e",
    perfStats.dtMin, perfStats.dtMax, perfStats.dtAvg),x,y)
end

function playdate.update() 
    if not world_setup then
        setup()
    end
    local now = playdate.getCurrentTimeMilliseconds()
    local dt = (now - lastPhysTime)/1000
    --if dt > 50 then dt = 50 end -- minimum physics update 20Hz, slowdown instead after that
    --updatePerf(dt)
    --drawPerf(25,0)
    --playdate.drawFPS(0,0)
    updateGravity()
    World.space:step(dt)
    gfx.sprite.update()
   lastPhysTime = now
    lastGrafTime = now
 
    
end