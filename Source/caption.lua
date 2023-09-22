import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics
local geom = playdate.geometry

class('Caption').extends(gfx.sprite)

function Caption:init()
    Caption.super.init(self)
    self.text = nil
    self:moveTo(0,0)
    self:setCenter(0,0)
    self:setSize(400,18)
end

function Caption:setText(val)
    self.text = val
    self:markDirty()
end

function Caption:clearText()
    self.text = nil
    self:markDirty()
end

function Caption:draw()
    gfx.setBackgroundColor(gfx.kColorWhite)
    gfx.setColor(gfx.kColorBlack)
    if self.text ~= nil then
        gfx.drawText(self.text, 0, 0)
    end
end