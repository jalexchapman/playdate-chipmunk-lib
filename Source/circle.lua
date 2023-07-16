import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics

class('Circle').extends(gfx.sprite)

function Circle:init(body, xOffset, yOffset, radius, friction, elasticity)
    Circle.super.init(self)

    self.radius = radius
    -- self.density = density
    self.friction = friction
    self.elasticity = elasticity
    self.angle = 0
    self.xOffset = xOffset
    self.yOffset = yOffset
    self._body = body
    local x, y = self._body:getPosition()
    x += xOffset
    y += yOffset
    self.prevX = x
    self.prevY = y
    self.prevAngle = self.angle

    self._shape = chipmunk.shape.newCircle(self._body, radius, xOffset, yOffset)
    self._shape:setFriction(friction)
    self._shape:setElasticity(elasticity)

    --gfx.sprite stuff
    local diameter=  radius * 2 + 1
    self:setSize(diameter, diameter)
    self:setCenter(0.5, 0.5)
    self:setCollideRect(0, 0, diameter, diameter)
    self:moveTo(x, y)

    self.alpha = 1.0

    World.space:addShape(self._shape)
    self:addSprite()
end

function Circle:update()
    local a = self._body:getAngle()
    local x, y = self._body:getPosition()

    local xOff = self.xOffset
    local yOff = self.yOffset

    if (xOff ~=0 or yOff ~= 0) then
        if a ~=0 then --FIXME: correct but new affine every frame likely slow
            local rot = playdate.geometry.affineTransform.new()
            rot:rotate(math.deg(a))
            xOff, yOff = rot:transformXY(xOff, yOff)
        end

        x += xOff
        y += yOff            
    end

    self.prevX = self.x
    self.prevY = self.y
    self.prevAngle = self.angle

    --round to nearest int to avoid redrawing subpixel moves
    a = math.floor(a * 100 + 0.5)/100 --pesky radians
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)
    self:moveTo(x,y)

    if (a ~= self.angle) then
        self.angle = a
        self:markDirty() -- ensure rotation in place
    end
end

function Circle:draw()
    local pattern = SolidPattern
    local useOutline = false
    gfx.setColor(gfx.kColorBlack)
    if self.isControllable then
        pattern = ControllablePattern
        useOutline = true
    end
    Circle.drawStatic(self.radius, self.angle, pattern, gfx.kColorBlack, useOutline)
end

function Circle.drawStatic(radius, angle, pattern, color, useOutline)
    gfx.setColor(color)
    gfx.setPattern(pattern)
    gfx.fillCircleAtPoint(radius, radius, radius)
    gfx.setPattern(SolidPattern)
    if useOutline then
        gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(radius, radius, radius)
    end
    local xEdge = -1 * math.sin(angle) * radius
    local yEdge = math.cos(angle) * radius
    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(1)
    gfx.drawLine(
        radius + xEdge, radius + yEdge,
        radius - xEdge, radius - yEdge)
    if useOutline then
        gfx.setColor(color)
        gfx.drawCircleAtPoint(radius, radius, radius)
    end
end

function Circle:__gc()
    print("destroying circle")
    World.space:removeShape(self._shape)
    self:removeSprite()
    Circle.super.__gc(self)
end