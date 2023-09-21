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
    self:setImage(nil)
    self.selectedLine = 1
end

function Inspector:openWorld()
    if not self.isOpened then
        self.selectedLine = 1
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
            getter = function() return World:getGravityMagnitude() end,
            setter = function(val) World:setGravityMagnitude(val) end,
            type = Inspector.dataTypes.number,
            min = World.minGravity,
            max = World.maxGravity,
            format = "%.0f"},

            {label = "fluid drag",
            getter = function() return World.dragCoeff end,
            setter = function(val)
                World.dragCoeff = val
                for _, object in ipairs(DynamicObjects) do
                    object.dragCoeff = val
                end
            end,
            type = Inspector.dataTypes.number,
            min = 0,
            format = "%.5f"
            },

            {label = "surface k. fric",
            getter = function() return World.sliction end,
            setter = function(val) World.sliction = val end,
            type = Inspector.dataTypes.number,
            min = 0,
            max = 2,
            format = "%.3f"
            },

            {label = "surface st. fric",
            getter = function() return World.stiction end,
            setter = function(val)World.stiction = val end,
            type = Inspector.dataTypes.number,
            min = 0,
            max = 2,
            format = "%.3f"
            },

            {label = "tilt",
            getter = function() return World:isTiltEnabled() end,
            setter = function(value) World:setTiltEnabled(value) end,
            type = Inspector.dataTypes.bool}
        }
        self:cacheTableValues()
    end
end

function Inspector:openObject(obj)
    if not self.isOpened then
        self.target = obj
        self.selectedLine = 1
        local menuX = rightDefaultX
        if obj.x > 200 then menuX = leftDefaultX end
        self:moveTo(menuX,defaultY)
        self:setSize(defaultWidth, defaultHeight)
        self:addSprite()
        self:setCenter(0,0)
        printTable(self.x, self.y)
        Inspector.playOpenSound()
        self.caption = "Object"
        self.isOpened = true
        self.targetDataTable = {
            {label = "edge friction",
            getter = function() return obj:getEdgeFriction() end,
            setter = function(val) obj:setEdgeFriction(val) end,
            type = Inspector.dataTypes.number,
            min = 0,
            max = 2,
            format = "%.3f"
            },
            {label = "elasticity",
            getter = function() return obj:getElasticity() end,
            setter = function(val) obj:setElasticity(val) end,
            type = Inspector.dataTypes.number,
            min = 0,
            max = 1,
            format = "%.3f"
            },
        }


        if obj:isa(Disc) or obj:isa(Box) then
            if obj:isa(Disc) then
                self.caption = "Disc"
            else
                self.caption = "Box"
            end
            -- add to targetDataTable:
            -- density
            -- surface static/dynamic friction
            -- isCrankable
            -- isAbsoluteCrank
            -- crankTorque
        elseif obj:isa(StaticSegment) then
            self.caption = "Static segment"
        else
            print("Error: inspector attempted to inspect unsupported object type. Object:")
            printTable(obj)
        end
        self:cacheTableValues()
    end
end


function Inspector:dismiss()
    if self.isOpened then
        self:applyDataTable()
        Inspector.playCloseSound()
        self.isOpened = false
        self.target = nil
        self.targetDataTable = nil
        self.selectedLine = 1
    end
    self:removeSprite()
end

function Inspector:cacheTableValues()
    for _, row in pairs(self.targetDataTable) do
        row.cachedValue = row.getter()
    end
end

function Inspector:applyDataTable()
    for _, row in pairs(self.targetDataTable) do
        if row.cachedValue ~= nil then
            row.setter(row.cachedValue)
        end
    end
end

function Inspector:update()
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        self:previousRow()
        self:markDirty()
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        self:nextRow()
        self:markDirty()
    elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
        self:decrease(playdate.buttonJustPressed(playdate.kButtonLeft))
        self:markDirty()
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        self:increase(playdate.buttonJustPressed(playdate.kButtonRight))
        self:markDirty()
    end
end

function Inspector:draw()
    local dividerHeight = marginWidth + 20
    gfx.setLineWidth(1)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, self.width, self.height)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(0,0,self.width, self.height)
    gfx.drawTextAligned("*" .. self.caption .. "*", self.width/2, marginWidth, kTextAlignment.center)
    gfx.drawLine(0, dividerHeight, self.width, dividerHeight)
    local leftText = ""
    local rightText = ""
    local highlight = false
    for index, row in ipairs(self.targetDataTable) do
        highlight = (self.selectedLine == index)
        local lineLabel = row.label
        if highlight then lineLabel = "*" .. lineLabel .. "*" end
        leftText = leftText .. lineLabel .. "\n"
        local valueString = tostring(row.cachedValue) -- TODO: enums will be trickier
        if row.format ~= nil then
            valueString = string.format(row.format, row.cachedValue)
        end
        if highlight then valueString = "*" .. valueString .. "*" end
        rightText = rightText .. valueString .."\n"
    end
    gfx.drawTextAligned(leftText, marginWidth, dividerHeight + 2, kTextAlignment.left)
    gfx.drawTextAligned(rightText, self.width - marginWidth, dividerHeight + 2, kTextAlignment.right)
end

function Inspector:nextRow()
    local len = #self.targetDataTable
    if self.targetDataTable and len > 0 then
        if self.selectedLine < len then self.selectedLine = self.selectedLine + 1 end
    end
end

function Inspector:previousRow()
    local len = #self.targetDataTable
    if self.targetDataTable and len > 0 then
        if self.selectedLine > 1 then self.selectedLine = self.selectedLine - 1 end
    end
end

function Inspector:increase(isInitialPress)
    local row = self.targetDataTable[self.selectedLine]
    if (not isInitialPress) and row.type ~= Inspector.dataTypes.number then
        return
    end
    if row.type == Inspector.dataTypes.bool then
        row.cachedValue = true
    elseif row.type == Inspector.dataTypes.number then
        if row.min ~= nil and row.max ~= nil then
            local step = (row.max - row.min)/150 --5 seconds to scrub full range
            row.cachedValue += step
        else
            row.cachedValue *= 1.015
        end
        if row.max ~= nil then row.cachedValue = math.min(row.max, row.cachedValue) end
    else
        print("Increase value")
    end
end

function Inspector:decrease(isInitialPress)
    local row = self.targetDataTable[self.selectedLine]
    if (not isInitialPress) and row.type ~= Inspector.dataTypes.number then
        return
    end
    if row.type == Inspector.dataTypes.bool then
        row.cachedValue = false
    elseif row.type == Inspector.dataTypes.number then
        -- can use range?
        if row.min ~= nil and row.max ~= nil then
            local step = (row.max - row.min)/150 --5 seconds to scrub full range
            row.cachedValue -= step
        else
            row.cachedValue *= 0.975
        end
        if row.min ~= nil then row.cachedValue = math.max(row.min, row.cachedValue) end
    else
        print("Decrease value")
    end
end

function Inspector.playOpenSound()
    openSound:play(1)
end

function Inspector.playCloseSound()
    closeSound:play(1)
end