import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics
local geom = playdate.geometry

class('StaticSegment').extends(gfx.sprite)

function StaticSegment:init(pointA, pointB, radius, friction, elasticity)
    StaticSegment.super.init(self)

    self.radius = radius
    self.a = pointA
    self.b = pointB

    --chipmunk properties
    self.friction = friction
    self.elasticity = elasticity
    self._body = World.staticBody
    self._shape = chipmunk.shape.newSegment(self._body,pointA.x, pointA.y, pointB.x, pointB.y, radius)
    self._shape:setFriction(friction)
    self._shape:setElasticity(elasticity)
    World.space:addShape(self._shape)

    --sprite proerties
    local spriteRect = StaticSegment.getBoundingRect(pointA, pointB, radius)
    self:setSize(spriteRect.width, spriteRect.height)
    self:setCenter(0,0)
    self:setCollideRect(0, 0, self.width, self.height)
    self:moveTo(spriteRect.x, spriteRect.y)
    self:addSprite()
end

function StaticSegment.getBoundingRect(a, b, radius)
    local diameter = radius * 2
    local boundingRect = geom.rect.new(geom.rect.fast_union(
        a.x - radius, a.y - radius, diameter, diameter,
        b.x - radius, b.y - radius, diameter, diameter))
    return boundingRect
end

function StaticSegment:getHitPoly()
    local minRadius = 4
    local lN = (self.b-self.a):leftNormal()
    local hitRadius = math.max(self.radius, minRadius)
    local offset = lN * hitRadius
    return geom.polygon.new(
        self.a + offset,
        self.b + offset,
        self.b - offset,
        self.a - offset)
end

function StaticSegment:pointHit(p)
    return self:getHitPoly():containsPoint(p)
end

function StaticSegment.drawAbsolute(a, b, radius, pattern, color)
    local diameter = radius * 2 - 1
    gfx.setLineCapStyle(gfx.kLineCapStyleRound)
    gfx.setLineWidth(diameter)
    gfx.setColor(color)
    gfx.setPattern(pattern)
    gfx.drawLine(a.x, a.y, b.x, b.y)
end

function StaticSegment.drawRelative(a, b, radius, pattern, color, origin)
    local correction = geom.vector2D.new(-(origin.x), -(origin.y))
    StaticSegment.drawAbsolute(a + correction, b + correction, radius, pattern, color)
end

function StaticSegment:draw()
    local pattern = SolidPattern
    local color = gfx.kColorBlack
    StaticSegment.drawRelative(
        self.a, self.b, self.radius, pattern, color, geom.point.new(self.x, self.y))
end