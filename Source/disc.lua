import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"
import "Circle.lua"

local gfx = playdate.graphics

class('Disc').extends("Circle")

function Disc:init(x, y, radius, density, friction, elasticity)
    
    local mass = math.pi * radius^2 * density
    local moment = chipmunk.momentForCircle(mass, radius, 0, 0, 0)
    local body = chipmunk.body.newDynamic(mass, moment)
    body:setPosition(x, y)

    Disc.super.init(self, body, 0, 0, radius, friction, elasticity)
    self.mass = mass
    self.moment = moment

    self._dragConstraint = nil
    self._rotDragConstraint = nil
    self._frictionConstraint = nil
    self._rotFrictionConstraint = nil
end

function Disc:addSprite()
    Disc.super.addSprite(self)
    print("Disc:addSprite()")
    if self._dragConstraint then self._space:addConstraint(self._dragConstraint) end
    if self._rotDragConstraint then self._space:addConstraint(self._rotDragConstraint) end
    if self._frictionConstraint then self._space:addConstraint(self._frictionConstraint) end
    if self._rotFrictionConstraint then self._space:addConstraint(self._rotFrictionConstraint) end
    World.space:addBody(self._body)
end

function Disc:removeSprite()
    if self._dragConstraint then self._space:removeConstraint(self._dragConstraint) end
    if self._rotDragConstraint then self._space:removeConstraint(self._rotDragConstraint) end
    if self._frictionConstraint then self._space:removeConstraint(self._frictionConstraint) end
    if self._rotFrictionConstraint then self._space:removeConstraint(self._rotFrictionConstraint) end
    Disc.super.removeSprite(self)
    World.space:removeBody(self._body)
    print("Disc:removeSprite()")
end

function Disc:updateDrag()
end

function Disc:updateFriction()
end

function Disc:__gc()
    print("destroying disc")
    Disc.super.__gc(self)
end