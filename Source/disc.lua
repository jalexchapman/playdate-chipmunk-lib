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
    self.dragCoeff = .0015
    self.stiction = 0.3
    self.sliction = 0.25

    self.mass = mass
    self.moment = moment

    local dragConstraint = chipmunk.constraint.newPivotJoint(self._body, World.staticBody, 0, 0, 0, 0)
    self._dragConstraint = dragConstraint
    if dragConstraint ~= nil then
        dragConstraint:setMaxBias(0) -- we don't actually want to pivot
        dragConstraint:setMaxForce(0) -- update will set this
    end
    self._rotDragConstraint = nil
    self._floorFrictionConstraint = nil
    local floorFricConstraint = chipmunk.constraint.newPivotJoint(self._body, World.staticBody, 0, 0, 0, 0)
    self._floorFrictionConstraint = floorFricConstraint
    if floorFricConstraint ~= nil then
        floorFricConstraint:setMaxBias(0) -- don't actually pivot
        floorFricConstraint:setMaxForce(0) -- update will set this
    end
    self._rotFloorFrictionConstraint = nil
end

function Disc:addSprite()
    Disc.super.addSprite(self)
    print("Disc:addSprite()")
    if self._dragConstraint then World.space:addConstraint(self._dragConstraint) end
    if self._rotDragConstraint then World.space:addConstraint(self._rotDragConstraint) end
    if self._floorFrictionConstraint then World.space:addConstraint(self._floorFrictionConstraint) end
    if self._rotFloorFrictionConstraint then World.space:addConstraint(self._rotFloorFrictionConstraint) end
    World.space:addBody(self._body)
end

function Disc:removeSprite()
    if self._dragConstraint then World.space:removeConstraint(self._dragConstraint) end
    if self._rotDragConstraint then World.space:removeConstraint(self._rotDragConstraint) end
    if self._floorFrictionConstraint then World.space:removeConstraint(self._floorFrictionConstraint) end
    if self._rotFloorFrictionConstraint then World.space:removeConstraint(self._rotFloorFrictionConstraint) end
    Disc.super.removeSprite(self)
    World.space:removeBody(self._body)
    print("Disc:removeSprite()")
end

function Disc:updateDrag()
    if (self._dragConstraint ~= nil) then
        local vx, vy = self._body:getVelocity()
        --force = dragCoeff * frontal area * v^2; 
        self._dragConstraint:setMaxForce(self.dragCoeff * 2 * self.radius * (vx*vx + vy*vy))
    end
end


function Disc:updateFloorFriction()
    if (self._floorFrictionConstraint ~= nil) then
        local frictionCoeff = self.stiction
        local vx, vy = self._body:getVelocity()
        if (vx ~=0 or vy ~= 0) then
            frictionCoeff = self.sliction
        end
        self._floorFrictionConstraint:setMaxForce(frictionCoeff * World.gravity.z * self.mass)
        --local floorFric = math.abs(fZ) * frictionCoeff
    end
end

function Disc:update() --FIXME: this should be driven in physics loop, not this render call 
    Disc.super.update(self)
    self:updateDrag()
    self:updateFloorFriction()
end

function Disc:__gc()
    print("destroying disc")
    Disc.super.__gc(self)
end
