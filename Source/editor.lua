import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics
local geom = playdate.geometry

class('Editor').extends(gfx.sprite)

EditorModes = {
    delete = 1,
    toggleControl = 2
    -- segment = 3,
    -- disc = 4,
    -- box = 5,
}

local deleteImage = gfx.image.new('sprites/delete')
printTable(deleteImage)
local toggleControlImage = gfx.image.new('sprites/controllable')
printTable(toggleControlImage)
local segmentImage = gfx.image.new('sprites/addSegment')

function Editor:init()
    Editor.super.init(self)
    self.currentMode = 0
    self:enableMode(EditorModes.delete)
    self.cursorSpeed = 1.0
    self:moveTo(200,120)

end

function Editor:handleInput()
end

function Editor:update()
    --crank selects tool
    if (not playdate.isCrankDocked()) and playdate.getCrankChange() ~= 0 then
        local deg = playdate.getCrankPosition()
        if deg <= 180 and self.currentMode ~= EditorModes.delete then
            self:enableMode(EditorModes.delete)
        elseif deg > 180 and self.currentMode ~= EditorModes.toggleControl then
            self:enableMode(EditorModes.toggleControl)
        end
    end

    -- dpad input
    local dx, dy =  0,0
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        dy = -1 * self.cursorSpeed
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        dy = self.cursorSpeed
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = -1 * self.cursorSpeed
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = self.cursorSpeed
    end
    self:moveBy(dx, dy)
    if self.x > 400 then self:moveTo(400, self.y)
    elseif self.x < 1 then self:moveTo(1, self.y) end
    if self.y > 240 then self:moveTo(self.x, 240)
    elseif self.y < 1 then self:moveTo(self.x, 1) end

    --debug: test collisions
    if playdate.buttonJustPressed(playdate.kButtonB) then
        printTable(self:overlappingSprites())
    end
    
    if playdate.buttonJustPressed(playdate.kButtonA) then
        if self.currentMode == EditorModes.delete then self:deleteHere() end
        if self.currentMode == EditorModes.toggleControl then self:toggleControlHere() end
    end
end

function Editor:enableMode(modeNum)
    if math.floor(modeNum) ~= modeNum or modeNum > 2 or modeNum < 1 then
        print("Invalid parameter '" .. modeNum .. "' passed into enableMode. Must be an int from 1 to 2.")
        return
    end
    if modeNum == EditorModes.delete then
        self:setSize(32,32)
        self:setCenter(0.5,0.5)
        self:setCollideRect(16,16,2,2)
        self:setImage(deleteImage)
        self.currentMode = EditorModes.delete
        printTable(self:getImage())
    elseif modeNum == EditorModes.toggleControl then
        self:setSize(32,32)
        self:setCenter(0.5,0.5)
        self:setCollideRect(16,16,2,2)
        self:setImage(toggleControlImage)
        self.currentMode = EditorModes.toggleControl
        printTable(self:getImage())
    end
end

function Editor:deleteHere()
    local targets = self:overlappingSprites()
    for _, target in ipairs(targets) do
        local hit = false
        for i = #DynamicObjects, 1, -1 do
            if DynamicObjects[i] == target then
                hit = true
                table.remove(DynamicObjects, i) -- shouldn't be dupes, but just to make sure, continue
            end
        end
        if hit then
            target:removeSprite()
        end
    end
end

function Editor:toggleControlHere()
    local targets = self:overlappingSprites()
    for _, target in ipairs(targets) do
        if target.toggleControl ~= nil then target:toggleControl() end
    end
end