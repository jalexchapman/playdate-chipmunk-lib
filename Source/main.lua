import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/object.lua'
import "circle.lua"
import "disc.lua"
import "world.lua"
import "box.lua"
import "settings.lua"
import "editor.lua"

local gfx = playdate.graphics
gfx.setColor(gfx.kColorBlack)

FixedStepMs = 10 --100fps/10ms physics
StepAccumulator = 0
MaxStepsPerFrame = 7 --allow slowdown if it frame time is over 70ms - 15fps may be tolerable
LastUpdate = 0
DynamicObjects = {}
CrankAngle = 0

DefaultObjectDensity = 0.003
DefaultObjectFriction = 0.5
DefaultObjectElasticity = 0.8

SolidPattern = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}
ControllablePattern = {0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55}
PlacementPattern = {0xaa,0x00,0xaa,0x00,0xaa,0x00,0xaa,0x00,0xaa,0x55,0xaa,0x55,0xaa,0x55,0xaa,0x55}

TorqueCrankPower = 1000

MaxCrankForce = 80000
EditorSprite = nil

local world_setup = false

local stiction = 0.3
local sliction = 0.25
local dragCoeff = 0.0015

wallSegments = {} -- fixme: local?
DynamicObjects = {}


function updateGravity()
    local x, y, z = playdate.readAccelerometer()
    World:setGravity(x, y, z)
end

function addRandomCircle()
    local radius = math.random(5, 30)
    local x = math.random(radius + 1, 399 - radius)
    local y = math.random(radius + 1, 239 - radius)

    local newDisc = Disc(x, y, radius, DefaultObjectDensity, DefaultObjectFriction, DefaultObjectElasticity)
    if (newDisc ~= nil) then
        table.insert(DynamicObjects, newDisc)
    end
    return newDisc
end

function addRandomBox()
    local halfwidth = math.random(3, 20)
    local halfheight = math.random(3,20)
    local x = math.random(halfwidth + 1, 399 - halfwidth)
    local y = math.random(halfheight + 1, 239 - halfheight)

    local newBox = Box(x, y, halfwidth * 2, halfheight * 2, 2,
        DefaultObjectDensity, DefaultObjectFriction, DefaultObjectElasticity
    )
    if newBox ~= nil then
        table.insert(DynamicObjects, newBox)
    end
    return newBox

end

function addPeg(r, x, y)
    local friction = 0.6
    local elasticity = 0.7
    local peg = Circle(World.staticBody, x, y, r, friction, elasticity)
    print("Adding peg size " .. r .. " at " .. x .."," .. y)
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
    playdate.display.setRefreshRate(0) --update has its own frame limiter
    playdate.startAccelerometer() --tilt is on by default
    World:setup()
    
    Settings.menuSetup()

    EditorSprite = Editor()


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
    DynamicObjects[1]:toggleControl()
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0,0,400,240)

    world_setup = true
end

local function drawPhysConstants(x, y)
    gfx.drawText(string.format(
        "stic: %.3f slic: %.3f drag: %.5f grav: %.0f",
        stiction, sliction, dragCoeff, World.gravityMagnitude),x,y)
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
        for _, object in ipairs(DynamicObjects) do
            object.stiction = stiction
            object.sliction = sliction
            object.dragCoeff = dragCoeff
            object:setEdgeFriction(stiction)
        end
    end

    if not playdate.isCrankDocked()
    then
        local crankAmt = playdate.getCrankChange()
        if crankAmt ~= 0 then
            World.gravityMagnitude += playdate.getCrankChange() * 10
            if World.gravityMagnitude > World.maxGravity then World.gravityMagnitude = World.maxGravity end
            if World.gravityMagnitude < World.minGravity then World.gravityMagnitude = 0 end
            if not Settings.accelEnabled then
                World:setGravity(0,1,0) -- refresh gravity vector
            end
        end
    end
end

local function updatePositionCrankSettings()
    local forceChanged = false
    if playdate.buttonIsPressed(playdate.kButtonDown)
    then
        forceChanged = true
        MaxCrankForce *= 0.975
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then 
        forceChanged = true
        MaxCrankForce *= 1.015
    end
    if forceChanged then
        for _, object in ipairs(DynamicObjects) do
            if object.setPositionCrankForce ~= nil then
                object:setPositionCrankForce(MaxCrankForce)
            end
        end
    end
end

local function drawPositionCrankSettings(x, y)
    gfx.drawText(string.format("Torque: %.0f", MaxCrankForce), x, y)
end

local function updateFrictionAndDragValues()
    if Settings.dragEnabled then
        for _, item in ipairs(DynamicObjects) do
            --printTable(item)
            item:updateDrag()
        end
    end
end

local function updateTorqueCrankSettings()
    local forceChanged = false
    if playdate.buttonIsPressed(playdate.kButtonDown)
    then
        forceChanged = true
        TorqueCrankPower *= 0.975
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then 
        forceChanged = true
        TorqueCrankPower *= 1.015
    end
end

local function drawTorqueCrankSettings(x, y)
    gfx.drawText(string.format("Torque: %.0f", TorqueCrankPower), x, y)
end


function updateInputs()
    if Settings.inputMode == InputModes.setConstants then
        updatePhysConstants()
    elseif Settings.inputMode == InputModes.positionCrank then
        if not playdate.isCrankDocked() then
            CrankAngle = playdate.getCrankPosition()
        end
        updatePositionCrankSettings()
    elseif Settings.inputMode == InputModes.torqueCrank then
        if not playdate.isCrankDocked() then
            local crankRate = playdate.getCrankChange()
            for _, object in ipairs(DynamicObjects) do -- FIXME: there must be a better home for this
                if object.isControllable and object.applyTorque ~= nil then
                    object:applyTorque(crankRate * TorqueCrankPower)
                end
            end
        end
        updateTorqueCrankSettings()
    end
    if Settings.accelEnabled then
        updateGravity() --FIXME: consider polling accel every physics step? Subtly laggy
    end

end

function updateChipmunk(dtSeconds)
    if Settings.inputMode ~= InputModes.editObjects then -- pause simulation in editor
        updateFrictionAndDragValues()
        World.space:step(dtSeconds)
    end
end

function turnCrankBodyTo(targetAngleDeg, dtSeconds)
    if dtSeconds <= 0 then
        print("ERROR: dtSeconds must be positive! Value given: " .. dtSeconds)
        return
    end

    local targetAngle = math.rad(targetAngleDeg)
    local currentAngle = World.crankBody:getAngle()
    local diff = targetAngle - currentAngle
    while diff > math.pi do
        diff -= 2 * math.pi
    end
    while diff < -1 * math.pi do
        diff += 2 * math.pi
    end
    World.crankBody:setAngularVelocity(diff / dtSeconds)
end

function updateGraphics()
    gfx.sprite.update()
    if Settings.inputMode == InputModes.setConstants then
        drawPhysConstants(0,0)
    elseif Settings.inputMode == InputModes.positionCrank then
        drawPositionCrankSettings(0,0)
    elseif Settings.inputMode == InputModes.torqueCrank then
        drawTorqueCrankSettings(0,0)
    end
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
    end

    if steps > 0 then
        local totalTimeSimulated = steps * fixedStepSec
        turnCrankBodyTo(CrankAngle, totalTimeSimulated)
    end

    for i=1, steps do
        updateChipmunk(fixedStepSec)
    end

    updateGraphics()

    playdate:drawFPS(15)
end