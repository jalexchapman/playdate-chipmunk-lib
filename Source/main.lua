import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'
import "circle.lua"
import "disc.lua"
import "world.lua"

local gfx = playdate.graphics
gfx.setColor(gfx.kColorBlack)

local world_setup = false

local gravityMagnitude=36778 -- limiting to minimize tunneling/glitching
local stiction = 0.3
local sliction = 0.25
local dragCoeff = 0.0015

--kGravityMagnitude = 66778 -- 9.8 m/s^2, 173 ppi = 6811 px/m
wallSegments = {}
allConstraints = {}
local discs = {}
local lastPhysTime = 0
local lastGrafTime = 0

function updateGravity()
    local x, y, z = playdate.readAccelerometer()
    World:setGravity(x * gravityMagnitude, y * gravityMagnitude, z * gravityMagnitude)
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
        newDisc:addSprite()
        table.insert(discs, newDisc)
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
    --addPegs()
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

local function drawPhysConstants(x, y)
    gfx.drawText(string.format(
        "stic: %.3f slic: %.3f drag: %.5f grav: %.0f",
        stiction, sliction, dragCoeff, gravityMagnitude),x,y)
end

local function updatePhysConstants()
    local frictionChanged = false
    local dragChanged = false
    if playdate.buttonIsPressed(playdate.kButtonDown)
    then
        frictionChanged = true
        stiction -= .001
        if stiction < 0 then stiction = 0 end
        if stiction < sliction then sliction = stiction end
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then 
        frictionChanged = true
        stiction += .001 
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft)
    then
        frictionChanged = true
        sliction -= .001
        if sliction < 0 then sliction = 0 end
    end
    if playdate.buttonIsPressed(playdate.kButtonRight)
    then
        frictionChanged = true
        sliction += .001
        if stiction < sliction then stiction = sliction end
    end
    if playdate.buttonIsPressed(playdate.kButtonB) then 
        dragChanged = true
        dragCoeff -= .00005
        if dragCoeff < 0 then dragCoeff = 0 end
    end
    if playdate.buttonIsPressed(playdate.kButtonA) then 
        dragChanged = true
        dragCoeff += .00005 
    end

    if dragChanged or frictionChanged then
        for _, disc in ipairs(discs) do
            disc.stiction = stiction
            disc.sliction = sliction
            disc.dragCoeff = dragCoeff
        end
    end

    if not playdate.isCrankDocked()
    then
        gravityMagnitude += playdate.getCrankChange() * 10
        if gravityMagnitude > 66778 then gravityMagnitude = 66778 end
        if gravityMagnitude < 0.0 then gravityMagnitude = 0 end
    end
end

local function updateFrictionAndDragValues()
    for _, disc in ipairs(discs) do
        disc:updateDrag()
        disc:updateFloorFriction()
    end
    
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
    updatePhysConstants()
    updateGravity()
    updateFrictionAndDragValues()
    World.space:step(dt)
    gfx.sprite.update()
    drawPhysConstants(0,0)
    lastPhysTime = now
    lastGrafTime = now
end

