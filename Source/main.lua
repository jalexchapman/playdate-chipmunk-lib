import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'
import "circle.lua"
import "disc.lua"
import "world.lua"
import "box.lua"

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
local objects = {}
local lastPhysTime = 0
local lastGrafTime = 0
local nextPhysTime = 0
local nextGrafTime = 0
local lastGrafDt = 0
local lastPhysDt = 0
local minPhysInterval = 10
local minGrafInterval = 20
local luaPhys = true
local asynchronousUpdates = true
local drawEnabled = true

function updateGravity()
    local x, y, z = playdate.readAccelerometer()
    World:setGravity(x * gravityMagnitude, y * gravityMagnitude, z * gravityMagnitude)
end

function addRandomCircle()
    local radius = math.random(5, 30)
    local density = 0.003
    local friction = 0.3
    local elasticity = 0.8
    local x = math.random(radius + 1, 399 - radius)
    local y = math.random(radius + 1, 239 - radius)

    local newDisc = Disc(x, y, radius, density, friction, elasticity)
    if (newDisc ~= nil) then
        newDisc:addSprite()
        table.insert(objects, newDisc)
    end
    return newDisc
end

function addRandomBox()
    local halfwidth = math.random(3, 20)
    local halfheight = math.random(3,20)
    local density = 0.003
    local friction = 0.3
    local elasticity = 0.8
    local x = math.random(halfwidth + 1, 399 - halfwidth)
    local y = math.random(halfheight + 1, 239 - halfheight)

    local newBox = Box(x, y, halfwidth * 2, halfheight * 2, 2,
        density, friction, elasticity
    )
    if newBox ~= nil then
        newBox:addSprite()
        table.insert(objects, newBox)
    end
    return newBox

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
    playdate.display.setRefreshRate(0) --update has its own frame limiter
    World:setup()
    
    local menu = playdate.getSystemMenu()
    menu:addCheckmarkMenuItem("lua phys", true, function(value)
        luaPhys = value
    end)
    menu:addCheckmarkMenuItem("async", true, function(value)
        asynchronousUpdates = value
    end)
    menu:addCheckmarkMenuItem("draw", true, function(value)
        drawEnabled = value
    end)    

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
    for i=1,3 do
       addRandomCircle()
       addRandomBox()
    end
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)
    lastPhysTime = playdate.getCurrentTimeMilliseconds()
    lastGrafTime = lastPhysTime
    world_setup = true
end

local perfStats = {samples=0, dtMax=0, dtMin = math.huge, dtAvg = 0}

-- local function updatePerf(dt)
--     local agg = perfStats.samples * perfStats.dtAvg
--     perfStats.samples = perfStats.samples + 1
--     agg = agg + dt
--     perfStats.dtAvg = agg/perfStats.samples
--     if 0 < dt and dt < perfStats.dtMin then perfStats.dtMin = dt end
--     if dt > perfStats.dtMax then perfStats.dtMax = dt end
-- end

-- local function drawPerf(x, y) -- there is another drawPerf - don't just uncomment
--     gfx.drawText(string.format( -- draw perf
--     "min dt: %e\nmax dt: %e\nmean dt: %e",
--     perfStats.dtMin, perfStats.dtMax, perfStats.dtAvg),x,y)
-- end

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
        for _, object in ipairs(objects) do
            object.stiction = stiction
            object.sliction = sliction
            object.dragCoeff = dragCoeff
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
    if luaPhys then
        for _, item in ipairs(objects) do
            item:updateLinearDrag()
            item:updateRotationalDrag()
        end
    end
end

function updateInputs()
    updatePhysConstants()
    if luaPhys then
        updateGravity()
    end
end

function updateChipmunk(dtSeconds)
    updateFrictionAndDragValues()
    World.space:step(dtSeconds)
end

function updateGraphics()
    if drawEnabled then
        gfx.sprite.update()
    else --clear the debug box
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0,0,400,33)
    end
    drawPhysConstants(0,0)
end

function drawPerf(x,y)
    local physFrameRate = 0
    local grafFrameRate = 0
    if lastPhysDt > 0 then
        physFrameRate = 1000/lastPhysDt
    end
    if lastGrafDt > 0 then
        grafFrameRate = 1000/lastGrafDt
    end
    gfx.drawText(string.format(
        "graphics: %.0f",
        grafFrameRate),x,y)
    gfx.drawText(string.format(
        "physics: %.0f ",
        physFrameRate),x + 120 ,y)

end

function playdate.update() 
    if not world_setup then
        setup()
        lastGrafTime = playdate.getCurrentTimeMilliseconds()
        lastPhysTime = lastGrafTime
        nextGrafTime = lastGrafTime + minGrafInterval
        nextPhysTime = lastPhysTime + minGrafInterval
    end
    local now = playdate.getCurrentTimeMilliseconds()
    updateInputs()

    if not asynchronousUpdates or now > nextPhysTime then
        local physDt = now - lastPhysTime
        lastPhysTime = now
        updateChipmunk(physDt/1000)
        lastPhysDt = physDt
        nextPhysTime = now + minPhysInterval
    end

    if not asynchronousUpdates or now > nextGrafTime then
        local grafDt = now - lastGrafTime
        lastGrafTime = now
        updateGraphics()
        lastGrafDt = grafDt
        -- if lastPhysDt > 20 then -- cut graphics rate to protect physics stability
        --     nextGrafTime = now + 2.5 * minGrafInterval
        -- else
            nextGrafTime = now + minGrafInterval
        -- end
        drawPerf(0,15)
    end
end

