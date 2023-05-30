import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics

class('Disc').extends(gfx.sprite)


function Disc:init(x, y, radius, density, friction, elasticity)
    Disc.super.init(self)

    self.radius = radius
    self.density = density
    self.friction = friction
    self.elasticity = elasticity
    self.mass = math.pi * radius^2 * density
    self.moment = chipmunk.momentForCircle(self.mass, radius, 0, 0, 0)

    self._body = chipmunk.body.newDynamic(self.mass, self.moment)
    self._body:setPosition(x, y)

    self._shape = chipmunk.shape.newCircle(self._body, radius, 0, 0)
    self._shape:setFriction(friction)
    self._shape:setElasticity(elasticity)

    self._dragConstraint = nil
    self._rotDragConstraint = nil
    self._frictionConstraint = nil
    self._rotFrictionConstraint = nil

    --gfx.sprite stuff
    self:setSize(radius * 2 + 1, radius * 2 + 1)
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    print("initialized disc")

end

function Disc:addSprite()
    Disc.super.addSprite(self)
    print("Disc:addSprite()")
     if self._dragConstraint then self._space:addConstraint(self._dragConstraint) end
    if self._rotDragConstraint then self._space:addConstraint(self._rotDragConstraint) end
    if self._frictionConstraint then self._space:addConstraint(self._frictionConstraint) end
    if self._rotFrictionConstraint then self._space:addConstraint(self._rotFrictionConstraint) end
    World.space:addBody(self._body)
    World.space:addShape(self._shape)
end

function Disc:removeSprite()
    if self._dragConstraint then self._space:removeConstraint(self._dragConstraint) end
    if self._rotDragConstraint then self._space:removeConstraint(self._rotDragConstraint) end
    if self._frictionConstraint then self._space:removeConstraint(self._frictionConstraint) end
    if self._rotFrictionConstraint then self._space:removeConstraint(self._rotFrictionConstraint) end
    World.space:removeShape(self._shape)
    World.space:removeBody(self._body)
    Disc.super.removeSprite(self)
end

function Disc:updateDrag()
end

function Disc:updateFriction()
end


function Disc:draw()
    local x, y = self._body:getPosition()
    self:moveTo(x,y)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(self.radius, self.radius, self.radius)
    local a = self._body:getAngle()
    local r = self.radius
    local xEdge = math.cos(a) * r
    local yEdge = math.sin(a) * r
    gfx.setColor(gfx.kColorWhite)
    gfx.drawLine(r + xEdge, r + yEdge, r - xEdge, r - yEdge)
end

function Disc:__gc()
    print("destroying disc")
    self:removeSprite()
    Disc.super.__gc(self)
end