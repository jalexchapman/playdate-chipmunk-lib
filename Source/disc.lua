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

    local linearDragConstraint = chipmunk.constraint.newPivotJoint(self._body, World.staticBody, 0, 0, 0, 0)
    if linearDragConstraint ~= nil then
        linearDragConstraint:setMaxBias(0) -- we don't actually want to pivot
        linearDragConstraint:setMaxForce(0) -- update will set this
    end
    self._linearDragConstraint = linearDragConstraint
    
     local rotDragConstraint = chipmunk.constraint.newGearJoint(self._body, World.staticBody, 0, 1)
     if rotDragConstraint ~= nil then
        rotDragConstraint:setMaxBias(0)
        rotDragConstraint:setMaxForce(0)
     end
     self._rotDragConstraint = rotDragConstraint
    
end

function Disc:addSprite()
    Disc.super.addSprite(self)
    print("Disc:addSprite()")
    if self._linearDragConstraint then World.space:addConstraint(self._linearDragConstraint) end
    if self._rotDragConstraint then World.space:addConstraint(self._rotDragConstraint) end
    World.space:addBody(self._body)
end

function Disc:removeSprite()
    if self._linearDragConstraint then World.space:removeConstraint(self._linearDragConstraint) end
    if self._rotDragConstraint then World.space:removeConstraint(self._rotDragConstraint) end
   Disc.super.removeSprite(self)
    World.space:removeBody(self._body)
    print("Disc:removeSprite()")
end

-- update linear fluid drag and linear friction against the floor play surface
function Disc:updateLinearDrag()
    if (self._linearDragConstraint ~= nil) then
        local drag = 0
        local friction = 0
        local vx, vy = self._body:getVelocity()
        local w = self._body:getAngularVelocity()
        --viscous drag = dragCoeff * frontal area * v^2; 
        drag = self.dragCoeff * 2 * self.radius * (vx*vx + vy*vy)
        local frictionCoeff = self.stiction
        if (vx ~=0 or vy ~= 0 or w ~= 0) then
            frictionCoeff = self.sliction
        end
        --Coulomb drag = coefficient of friction * normal force
        friction = frictionCoeff * math.abs(World.gravity.z) * self.mass --abs: assuming same friction on screen front/back surfaces
        self._linearDragConstraint:setMaxForce(drag + friction)
    end
end

function Disc:updateRotationalDrag()
    if self._rotDragConstraint ~= nil then
        local frictionCoeff = self.stiction
        local vx, vy = self._body:getVelocity()
        local w = self._body:getAngularVelocity()
        if (vx ~=0 or vy ~= 0 or w ~= 0) then
            frictionCoeff = self.sliction
        end
        local friction = 0
        -- Torque = 2/3 coefficient of friction * normal force * radius
        friction = 0.6667 * frictionCoeff * math.abs(World.gravity.z) * self.mass * self.radius
        self._rotDragConstraint:setMaxForce(friction)
        --TODO: viscous drag?
    end
end

function Disc:__gc()
    print("destroying disc")
    Disc.super.__gc(self)
end
