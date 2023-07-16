import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics
local geom = playdate.geometry

class('SegmentPreview').extends(gfx.sprite)

function SegmentPreview:init()
    SegmentPreview.super.init(self)
    self.startPoint = geom.point.new(0,0)
    self.endPoint = geom.point.new(0,0)
    self.radius = 1
    self:moveTo(0,0)
    self:setCenter(0,0)
end

function SegmentPreview:update()
    local rect = StaticSegment.getBoundingRect(self.startPoint, self.endPoint, self.radius)
    self:setSize(rect.width, rect.height)
    self:moveTo(rect.x, rect.y)
end

function SegmentPreview:draw()
    StaticSegment.drawRelative(
        self.startPoint, self.endPoint, self.radius, 
        SolidPattern, gfx.kColorBlack, 
        geom.point.new(self.x, self.y))
end