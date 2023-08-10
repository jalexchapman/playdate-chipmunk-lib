import "CoreLibs/sprites.lua"
import "CoreLibs/graphics.lua"
import "disc"
import "box"

local gfx = playdate.graphics
local snd = playdate.sound

class('Inspector').extends(gfx.sprite)

local defaultWidth = 250
local defaultHeight = 200
local leftDefaultX = 20
local rightDefaultX = 400 - leftDefaultX - defaultWidth
local defaultY = 20
local marginWidth = 5
local openSound = snd.sampleplayer.new('sounds/open')
local closeSound = snd.sampleplayer.new('sounds/close')

Inspector.dataTypes = {
    number = 1,
    bool = 2
}

function Inspector:init()
    Inspector.super.init(self)
    self:moveTo(rightDefaultX,defaultY)
    self:setSize(defaultWidth, defaultHeight)
    self:setCenter(0,0)
    self.isOpened = false
    self.target = nil
    self:setZIndex(32767)
    self.leftText = nil
    self.rightText = nil
    self.caption = nil
    self.targetDataTable = nil
    self.waitForPadRelease = false
    self:setImage(nil)
end

function Inspector:openWorld()
    if not self.isOpened then
        self:moveTo(rightDefaultX,defaultY)
        self:setSize(defaultWidth, defaultHeight)
        self:addSprite()
        self:setCenter(0,0)
        printTable(self.x, self.y)
        Inspector.playOpenSound()
        self.caption = "World"
        self.isOpened = true

        self.target = World
        self.targetDataTable = {
            {label = "gravity",
            getter = function() World:getGravityMagnitude() end,
            setter = function(val) World:setGravityMagnitude(val) end,
            type = Inspector.dataTypes.number,
            min = World.minGravity,
            max = World.maxGravity},
            {label = "tilt",
            getter = function() World:isTiltEnabled() end,
            setter = function(value) World:setTiltEnabled(value) end,
            type = Inspector.dataTypes.boolean}
        }

        printTable(self.targetDataTable)
        self:markDirty()
    end
end

function Inspector:openObject(obj)
    if obj:isa(Disc) then
        print("Inspect disc")
    elseif obj:isa(Box) then
        print("Inspect box")
    elseif obj:isa(Segment) then
        print("Inspect segment")
    else
        print("Error: inspector attempted to inspect unsupported object type. Object:")
        printTable(obj)
    end
end



function Inspector:dismiss()
    if self.isOpened then
        --TODO: apply all values
        Inspector.playCloseSound()
        self.isOpened = false
        self.target = nil
        self.targetDataTable = nil
    end
    self:removeSprite()
end

function Inspector:update()
    if waitForPadRelease then
        if not (playdate.buttonIsPressed(playdate.kButtonUp) or playdate.buttonIsPressed(playdate.kButtonDown)) then
            waitForPadRelease = false
        end
    else
        if playdate.buttonIsPressed(playdate.kButtonUp) then
            print("up")
            waitForPadRelease = true
            self:markDirty()
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then
            print("down")
            waitForPadRelease = true
            self:markDirty()
        end
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        print("left")
        self:markDirty()
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        print("right")
        self:markDirty()
    end
end

function Inspector:draw()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, self.width, self.height)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(0,0,self.width, self.height)
end



function Inspector.playOpenSound()
    openSound:play(1)
end

function Inspector.playCloseSound()
    closeSound:play(1)
end