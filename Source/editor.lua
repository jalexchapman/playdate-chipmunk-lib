import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics
local geom = playdate.geometry

class('Editor').extends(gfx.sprite)

EditorModes = {
    delete = 1,
    toggleControl = 2,
    disc = 3,
    box = 4
    -- segment = 5
}

local deleteImage = gfx.image.new('sprites/delete')
printTable(deleteImage)
local toggleControlImage = gfx.image.new('sprites/crankcursor')
printTable(toggleControlImage)
local segmentImage = gfx.image.new('sprites/addSegment')

local minDiscRadius = 4
local maxDiscRadius = 119
local minBoxWidth = 8
local maxBoxWidth = 398
local minBoxHeight = 8
local maxBoxHeight = 238

function Editor:init()
    Editor.super.init(self)
    self.currentMode = 0
    self:enableMode(EditorModes.delete)
    self.cursorMoveDuration = 0
    self:moveTo(200,120)
    self.resizing = false
    self.discRadius = 30
    self.boxWidth = 30
    self.boxHeight = 30
    self:clearInputState()
    self:setZIndex(32767)
end

function Editor:update()
    self:crankSelectMode()

    -- dpad input
    local dx, dy =  0,0
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        dy -= 1
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        dy +=1
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx -=1
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        dx +=1
    end

    if self.resizing then
        if self.currentMode == EditorModes.disc then
            self:resizeDisc(dx)
        elseif self.currentMode == EditorModes.box then
            self:resizeBox(dx, dy)
        end
    else
        self:moveCursor(dx, dy)
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        if self.currentMode == EditorModes.delete then self:deleteHere() end
        if self.currentMode == EditorModes.toggleControl then self:toggleControlHere() end
        if self.currentMode == EditorModes.disc then self:stampDisc() end
        if self.currentMode == EditorModes.box then self:stampBox() end
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        if self.currentMode == EditorModes.disc or
              self.currentMode == EditorModes.box then
            self.resizing = true
        end
    end

    if playdate.buttonJustReleased(playdate.kButtonB) then
        self.resizing = false
    end
end

function Editor:clearInputState()
    self.cursorMoveDuration = 0
    self.resizing = false
end

function Editor:crankSelectMode()
    --crank selects tool
    if (not playdate.isCrankDocked()) and playdate.getCrankChange() ~= 0 then
        local deg = playdate.getCrankPosition()
        if deg <= 90 then
            if self.currentMode ~= EditorModes.delete then
                self:enableMode(EditorModes.delete)
                self:clearInputState()
            end
        elseif deg <= 180 then
            if self.currentMode ~= EditorModes.toggleControl then
                self:enableMode(EditorModes.toggleControl)
                self:clearInputState()
            end
        elseif deg <= 270 then
            if self.currentMode ~= EditorModes.disc then
                self:enableMode(EditorModes.disc)
                self:clearInputState()
            end
        else
            if self.currentMode ~= EditorModes.box then
                self:enableMode(EditorModes.box)
                self:clearInputState()
            end
        end
    end
end

function Editor:moveCursor(dx, dy)
    if dx==0 and dy==0 then
        self.cursorMoveDuration = 0
    else
        self.cursorMoveDuration += 1
        local speed = self:getCursorSpeed()
        dx *= speed
        dy *= speed
        self:moveBy(dx, dy)
        if self.x < 1 then self.moveTo(1, self.y)
        elseif self.x > 400 then self.moveTo(400, self.y) end
        if self.y < 1 then self.moveTo(self.x, 1)
        elseif self.y > 240 then self.moveTo(self.x, 240) end
    end
end

function Editor:getCursorSpeed()
    if self.cursorMoveDuration < 3 then
        return 1
    elseif self.cursorMoveDuration < 8 then
        return 2
    else
        return 4
    end
end

function Editor:resizeBox(dx, dy)
    if dx ~= 0 or dy ~= 0 then
        self.boxWidth += dx
        self.boxHeight -= dy -- up is bigger
        if self.boxWidth < minBoxWidth then self.boxWidth = minBoxWidth
        elseif self.boxWidth > maxBoxWidth then self.boxWidth = maxBoxWidth
        end
        if self.boxHeight < minBoxHeight then self.boxHeight = minBoxHeight
        elseif self.boxHeight > maxBoxHeight then self.boxHeight = maxBoxHeight
        end
        self:setSize(self.boxWidth, self.boxHeight)
        self:markDirty()
    end
end

function Editor:resizeDisc(dr)
    if dr ~= 0 then
        self.discRadius += dr
        if self.discRadius < minDiscRadius then self.discRadius = minDiscRadius
        elseif self.discRadius > maxDiscRadius then self.discRadius = maxDiscRadius
        end
        local breadth = self.discRadius * 2 + 1
        self:setSize(breadth, breadth)
        self:markDirty()
    end
end

function Editor:enableMode(modeNum)
    print("Editor:enableMode(" .. modeNum .. ")")
    if math.floor(modeNum) ~= modeNum or modeNum > 4 or modeNum < 1 then
        print("Invalid parameter '" .. modeNum .. "' passed into enableMode. Must be an int from 1 to 4.")
        return
    end
    if modeNum == EditorModes.delete then
        self:setSize(32,32)
        self:setCenter(0.5,0.5)
        self:setCollideRect(16,16,2,2)
        self:setImage(deleteImage)
        self.currentMode = EditorModes.delete
    elseif modeNum == EditorModes.toggleControl then
        self:setSize(32,32)
        self:setCenter(0,0)
        self:setCollideRect(1,1,2,2)
        self:setImage(toggleControlImage)
        self.currentMode = EditorModes.toggleControl
    elseif modeNum == EditorModes.disc then
        local breadth = (self.discRadius * 2) + 1
        self:setImage(nil)
        self:setCenter(0.5,0.5)
        self:setSize(breadth, breadth)
        self:setCollideRect(0,0,breadth, breadth)
        self.currentMode = EditorModes.disc
    elseif modeNum == EditorModes.box then
        self:setImage(nil)
        self:setCenter(0.5,0.5)
        self:setSize(self.boxWidth, self.boxHeight)
        self:setCollideRect(0,0,self.boxWidth, self.boxHeight)
        self.currentMode = EditorModes.box
    end
end

function Editor:draw()
    if self.currentMode == EditorModes.disc then
        Circle.drawStatic(self.discRadius, 0, PlacementPattern, gfx.kColorBlack, false)
    elseif self.currentMode == EditorModes.box then
        local tempPoly = geom.polygon.new(
            1, 1,
            self.boxWidth, 1,
            self.boxWidth, self.boxHeight,
            1, self.boxHeight,
            1, 1
        )
        Box.drawStatic(tempPoly, PlacementPattern, gfx.kColorBlack, false)
    else print("not sure how to draw when self.modeNum = ".. self.currentMode)
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

function Editor:stampDisc()
    local newDisc = Disc(self.x, self.y, self.discRadius, DefaultObjectDensity, DefaultObjectFriction, DefaultObjectElasticity)
    if newDisc ~= nil then
        table.insert(DynamicObjects, newDisc)
    end
end

function Editor:stampBox()
    local newBox = Box(self.x, self.y, self.boxWidth, self.boxHeight, 2,
        DefaultObjectDensity, DefaultObjectFriction, DefaultObjectElasticity)
    if newBox ~= nil then
        table.insert(DynamicObjects, newBox)
    end
end

function Editor:toggleControlHere()
    local targets = self:overlappingSprites()
    for _, target in ipairs(targets) do
        if target.toggleControl ~= nil then target:toggleControl() end
    end
end