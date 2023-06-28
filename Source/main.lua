import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'
import "circle.lua"
import "disc.lua"
import "world.lua"
import "box.lua"

local gfx = playdate.graphics
gfx.setColor(gfx.kColorBlack)

FixedStepMs = 10 --100fps/10ms physics
StepAccumulator = 0
MaxStepsPerFrame = 7 --allow slowdown if it frame time is over 70ms - 15fps may be tolerable
LastUpdate = 0

local world_setup = false

local gravityMagnitude=36778 -- limiting to minimize tunneling/glitching
local stiction = 0.3
local sliction = 0.25
local dragCoeff = 0.0015

--kGravityMagnitude = 66778 -- 9.8 m/s^2, 173 ppi = 6811 px/m
wallSegments = {}
allConstraints = {}
local objects = {}
local dragUpdates = true
local rotDragUpdates = true
local gravityUpdates = true

function updateGravity()
    if gravityUpdates then
        local x, y, z = playdate.readAccelerometer()
        World:setGravity(x * gravityMagnitude, y * gravityMagnitude, z * gravityMagnitude)
    end
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
    menu:addCheckmarkMenuItem("lin drag upd", true, function(value)
        dragUpdates = value
    end)
    menu:addCheckmarkMenuItem("rot drag upd", true, function(value)
        rotDragUpdates = value
    end)
    menu:addCheckmarkMenuItem("gravity upd", true, function(value)
        gravityUpdates = value
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
    for i=1,4 do
       addRandomCircle()
       addRandomBox()
    end
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)

    world_setup = true
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
    if dragUpdates or rotDragUpdates then
        for _, item in ipairs(objects) do
            if dragUpdates then item:updateLinearDrag() end
            if rotDragUpdates then item:updateRotationalDrag() end
        end
    end
end

function updateInputs()
    updatePhysConstants()
    updateGravity() --FIXME: consider polling accel every physics step? Subtly laggy

end

function updateChipmunk(dtSeconds)
    updateFrictionAndDragValues()
    World.space:step(dtSeconds)
end

function updateGraphics()
    gfx.sprite.update()
    drawPhysConstants(0,0)
end

function playdate.update() 
    if not world_setup then
        setup()
        LastUpdate = playdate.getCurrentTimeMilliseconds()
    end
    fixedRefresh()
end

function fixedRefresh() --derived from https://gafferongames.com/post/fix_your_timestep/
    local now = playdate.getCurrentTimeMilliseconds()
    updateInputs()

    local frameTime = now - LastUpdate
    StepAccumulator += frameTime
    LastUpdate = now
    
    local fixedStepSec = FixedStepMs / 1000
    local steps = 0

    while StepAccumulator >= FixedStepMs and steps < MaxStepsPerFrame do
        steps = steps + 1
        StepAccumulator -= FixedStepMs
        updateChipmunk(fixedStepSec)
    end

    updateGraphics()

    playdate:drawFPS(15)
end