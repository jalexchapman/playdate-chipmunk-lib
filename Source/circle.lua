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
    self:setSize(radius * 2 + 1, radius * 2 + 1)
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)

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
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(self.radius, self.radius, self.radius)
    local a = self.angle
    local r = self.radius
    local xEdge = math.cos(a) * r
    local yEdge = math.sin(a) * r
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(r + xEdge, r + yEdge, r - xEdge, r - yEdge)
end

function Circle:__gc()
    World.space:removeShape(self._shape)
    self:removeSprite()
    Circle.super.__gc(self)
end