import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "world.lua"
import "segmentpreview.lua"
import "inspector.lua"
import "caption.lua"

local gfx = playdate.graphics
local snd = playdate.sound
local geom = playdate.geometry

class('Editor').extends(gfx.sprite)

EditorModes = {
    delete = 1,
    inspect = 2,
    box = 3,
    disc = 4,
    segment = 5,
    toggleControl = 6
}

local deleteImage = gfx.image.new('sprites/delete')
local inspectImage = gfx.image.new('sprites/inspector')
local toggleControlImage = gfx.image.new('sprites/crankcursor')
local segmentImage = gfx.image.new('sprites/addSegment')

local clickSound = snd.sampleplayer.new('sounds/click')

local minDiscRadius = 4
local maxDiscRadius = 119
local minBoxWidth = 8
local maxBoxWidth = 398
local minBoxHeight = 8
local maxBoxHeight = 238
local minSegmentWidth = 2
local maxSegmentWidth = 40

function Editor:init()
    self.segmentPreviewer = SegmentPreview()
    self.caption = Caption()
    self.inspector = Inspector()

    Editor.super.init(self)
    self.currentMode = Editor.modeForAngle(CrankAngle)
    self:enableMode(self.currentMode)
    self.cursorMoveDuration = 0
    self:moveTo(200,120)
    self.resizing = false
    self.dragging = false
    self.discRadius = 15
    self.boxWidth = 30
    self.boxHeight = 30
    self:clearInputState()
    self:setZIndex(32765)

    self.segmentWidth = 2
    self.segmentStart = geom.point.new(0,0)
    self.segmentEnd = geom.point.new(0,0)
end

function Editor:addSprite()
    self.caption:addSprite()
    self.currentMode = Editor.modeForAngle(CrankAngle)
    self:enableMode(self.currentMode)
    Editor.super.addSprite(self)
    if self.currentMode == EditorModes.segment then
        self.segmentPreviewer:addSprite()
    end
end

function Editor:removeSprite()
    self.caption:removeSprite()
    self.segmentPreviewer:removeSprite()
    self:closeInspector()
    Editor.super.removeSprite(self)
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
            if dy ~= 0 then
                self:resizeDisc(-dy)
            else
                self:resizeDisc(dx)
            end
        elseif self.currentMode == EditorModes.box then
            self:resizeBox(dx, dy)
        elseif self.currentMode == EditorModes.segment then
            if dy ~= 0 then
                self:resizeLine(-dy)
            else
                self:resizeLine(dx)
            end
        end
    elseif self.currentMode ~= EditorModes.inspect or not self.inspector.isOpened then
        self:moveCursor(dx, dy)
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        if self.currentMode == EditorModes.delete then self:deleteHere() end
        if self.currentMode == EditorModes.inspect then self:inspectHere() end
        if self.currentMode == EditorModes.toggleControl then self:toggleControlHere() end
        if self.currentMode == EditorModes.disc then self:stampDisc() end
        if self.currentMode == EditorModes.box then self:stampBox() end
        if self.currentMode == EditorModes.segment then self:startSegment() end
    end

    if playdate.buttonJustReleased(playdate.kButtonA) then
        self:endSegment()
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        if self.currentMode == EditorModes.disc or
              self.currentMode == EditorModes.box or
              self.currentMode == EditorModes.segment then
            self.resizing = true
        end
        if self.currentMode == EditorModes.inspect then self:closeInspector() end
    end

    if playdate.buttonJustReleased(playdate.kButtonB) then
        self.resizing = false
    end
end

function Editor:clearInputState()
    self.cursorMoveDuration = 0
    self.resizing = false
    self.dragging = false
end

-- slice the crank arc into #EditorModes segments, centering the first at 0 degrees
function Editor:crankSelectMode()
    --crank selects tool
    if playdate.isCrankDocked() then
        self.caption:setText("Delete (Use crank to select tool)")
    else
        if CrankDelta ~= 0 then
            local slices = 6 --FIXME: #EditorModes doesn't seem to work? Don't like hardcoding
            local newMode = Editor.modeForAngle(CrankAngle)
            if self.currentMode ~= newMode then
                self:playClickSound()
                self:enableMode(newMode)
                self:clearInputState()
            end
        end
    end
end

function Editor.modeForAngle(crankAngle)
    local slices = 6 --FIXME: #EditorModes doesn't seem to work? Don't like hardcoding
    local mode = math.floor((CrankAngle * slices/360) + 1.5)
    if mode > slices then mode = 1 end
    return mode
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
        if self.x < 1 then self:moveTo(1, self.y)
        elseif self.x > 400 then self:moveTo(400, self.y) end
        if self.y < 1 then self:moveTo(self.x, 1)
        elseif self.y > 240 then self:moveTo(self.x, 240) end
        if self.currentMode == EditorModes.segment then
            self:updateSegment()
        end
    end
end

function Editor:getCursorSpeed()
    if self.cursorMoveDuration < 3 then
        return 1
    elseif self.cursorMoveDuration < 4 then
        return 2
    elseif self.cursorMoveDuration < 7 then
        return 4
    elseif self.cursorMoveDuration < 10 then
        return 6
    else
        return 8
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

function Editor:resizeLine(dw)
    if dw ~= 0 then
        self.segmentWidth += dw
        if self.segmentWidth < minSegmentWidth then self.segmentWidth = minSegmentWidth
        elseif self.segmentWidth > maxSegmentWidth then self.segmentWidth = maxSegmentWidth
        end
    end
    self:updateSegment()
end

function Editor:updateSegment()
    self.segmentEnd.x = self.x
    self.segmentEnd.y = self.y
    if not self.dragging then
        self.segmentStart.x = self.x
        self.segmentStart.y = self.y
    end
    self.segmentPreviewer.startPoint.x = self.segmentStart.x
    self.segmentPreviewer.startPoint.y = self.segmentStart.y
    self.segmentPreviewer.endPoint.x = self.segmentEnd.x
    self.segmentPreviewer.endPoint.y = self.segmentEnd.y
    self.segmentPreviewer.radius = self.segmentWidth / 2
end

function Editor:enableMode(modeNum)
    print("Editor:enableMode(" .. modeNum .. ")")
    if math.floor(modeNum) ~= modeNum or modeNum > 6 or modeNum < 1 then
        print("Invalid parameter '" .. modeNum .. "' passed into enableMode. Must be an int from 1 to 6.")
        return
    end
    if modeNum == EditorModes.delete then
        self.caption:setText("Delete")
        self:setSize(32,32)
        self:setCenter(0.5,0.5)
        self:setCollideRect(16,16,2,2)
        self:setImage(deleteImage)
        self.segmentPreviewer:removeSprite()
        self:closeInspector()
        self.currentMode = EditorModes.delete
    elseif modeNum == EditorModes.inspect then
        self.caption:setText("Inspect Object (click background for globals)")
        self:setSize(32,32)
        self:setCenter(0.344,0.344)
        self:setCollideRect(10,10,3,3)
        self:setImage(inspectImage)
        self.segmentPreviewer:removeSprite()
        self.currentMode = EditorModes.inspect     
    elseif modeNum == EditorModes.toggleControl then
        self.caption:setText("Toggle Crankable")
        self:setSize(32,32)
        self:setCenter(0,0)
        self:setCollideRect(1,1,2,2)
        self:setImage(toggleControlImage)
        self.segmentPreviewer:removeSprite()
        self:closeInspector()
        self.currentMode = EditorModes.toggleControl
    elseif modeNum == EditorModes.disc then
        self.caption:setText("Disc (B: hold to resize  A: place)")
        local breadth = (self.discRadius * 2) + 1
        self:setImage(nil)
        self:setCenter(0.5,0.5)
        self:setSize(breadth, breadth)
        self:setCollideRect(0,0,breadth, breadth)
        self.segmentPreviewer:removeSprite()
        self:closeInspector()
        self.currentMode = EditorModes.disc
    elseif modeNum == EditorModes.box then
        self.caption:setText("Box (B: hold to resize  A: place)")
        self:setImage(nil)
        self:setCenter(0.5,0.5)
        self:setSize(self.boxWidth, self.boxHeight)
        self:setCollideRect(0,0,self.boxWidth, self.boxHeight)
        self.segmentPreviewer:removeSprite()
        self:closeInspector()
        self.currentMode = EditorModes.box
    elseif modeNum == EditorModes.segment then
        self.caption:setText("Line (B: hold to resize  A: hold to draw)")
        self:setSize(32, 32)
        self:setCenter(0.5, 0.5)
        self:setCollideRect(16,16,2,2)
        self:setImage(segmentImage)
        self:updateSegment()
        self.segmentPreviewer:addSprite()
        self:closeInspector()
        self.currentMode = EditorModes.segment
    else
        print("Not sure what to do with seemingly valid mode " .. modeNum)
    end
end

function Editor:playClickSound()
    clickSound:play(1)
end

function Editor:draw()
    if self.currentMode == EditorModes.disc then
        Disc.drawStatic(self.discRadius, 0, PlacementPattern, gfx.kColorBlack, false)
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
    local hotspot = geom.point.new(self.x, self.y)
    local allSprites = playdate.graphics.sprite.getAllSprites()
    for _, target in ipairs(allSprites) do
        if target.pointHit ~= nil and target:pointHit(hotspot) then
            local hit = false
            for i = #DynamicObjects, 1, -1 do
                if DynamicObjects[i] == target then
                    hit = true
                    table.remove(DynamicObjects, i)
                end
            end
            for i = #StaticObjects, 1, -1 do
                if StaticObjects[i] == target then
                    hit = true
                    table.remove(StaticObjects, i)
                end
            end
            if hit then
                target:removeSprite()
                if target.removeLinearDragConstraint ~= nil then --FIXME: duplicate to keep __gc from crashing on remove[Linear|Rotary]DragConstraint
                    target:removeLinearDragConstraint()
                end
                if target.removeRotaryDragConstraint ~= nil then
                    target:removeRotaryDragConstraint()
                end
            end
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

function Editor:stampSegment()
    local newSegment = StaticSegment(self.segmentStart, self.segmentEnd, self.segmentWidth/2, DefaultObjectFriction, DefaultObjectElasticity)
    if newSegment ~= nil then
        table.insert(StaticObjects, newSegment)
    end
end

function Editor:startSegment()
    if self.currentMode == EditorModes.segment then
        self.dragging = true
    end
end

function Editor:endSegment()
    if self.dragging then
        self.dragging = false
        if self.currentMode == EditorModes.segment then
            self:stampSegment()
            self:updateSegment()
        end
    end
end

function Editor:toggleControlHere()
    local hotspot = geom.point.new(self.x, self.y)

    local allSprites = playdate.graphics.sprite.getAllSprites()
    for _, target in ipairs(allSprites) do
        if target.pointHit ~= nil and target:pointHit(hotspot) and target.toggleControl ~= nil then
            target:toggleControl()
        end
    end
end

function Editor:inspectHere()
    local hotspot = geom.point.new(self.x, self.y)
    local hit = nil
    local allSprites = playdate.graphics.sprite.getAllSprites()
    for _, target in ipairs(allSprites) do
        if target.pointHit ~= nil and target:pointHit(hotspot) then
            hit = target
        end
    end
    if hit then
        self.inspector:openObject(hit)
    else
        self.inspector:openWorld()
    end
end

function Editor:closeInspector()
    self.inspector:dismiss()
    --FIXME: if nothing else, just cut straight to dismiss
end