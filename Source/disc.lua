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
    World.space:addBody(self._body)

    self.dragCoeff = .0015
    self.stiction = 0.3
    self.sliction = 0.25

    self.mass = mass
    self.moment = moment

    self.isControllable = false
    self.isTorqueCrankable = false

    if Settings.linearDragEnabled then
        self:addLinearDragConstraint()
    end
    if Settings.rotaryDragEnabled then
        self:addRotaryDragConstraint()
    end
    if Settings.inputMode == InputModes.torqueCrank then
        self:enableTorqueCrank()
    elseif Settings.inputMode == InputModes.positionCrank then
        self:enablePositionCrank()
    end
end


function Disc:addLinearDragConstraint()
    if not self._linearDragConstraint then
        local linearDragConstraint = chipmunk.constraint.newPivotJoint(self._body, World.staticBody, 0, 0, 0, 0)
        if linearDragConstraint ~= nil then
            linearDragConstraint:setMaxBias(0) -- we don't actually want to pivot
            linearDragConstraint:setMaxForce(0) -- update will set this
        end
        self._linearDragConstraint = linearDragConstraint
        World.space:addConstraint(self._linearDragConstraint)
    end
end

function Disc:addRotaryDragConstraint()
    if not self._rotDragConstraint then
        local rotDragConstraint = chipmunk.constraint.newGearJoint(self._body, World.staticBody, 0, 1)
        if rotDragConstraint ~= nil then
            rotDragConstraint:setMaxBias(0)
            rotDragConstraint:setMaxForce(0)
        end
        self._rotDragConstraint = rotDragConstraint
        World.space:addConstraint(self._rotDragConstraint)
    end
end

function Disc:addDampedSpringConstraint()
    local restLength = 15
    local stiffness = 100
    local damping = 25
    local x, y = self._body:getPosition()
    local springConstraint = chipmunk.constraint.newDampedSpring(
        self._body, World.staticBody,
        0, 0, x, y,
        restLength,
        stiffness,
        damping
    )
    if springConstraint ~= nil then
        World.space:addConstraint(springConstraint)
        self._dampedSpringConstraint = springConstraint
    end
end

function Disc:removeLinearDragConstraint()
    if self._linearDragConstraint then 
        World.space:removeConstraint(self._linearDragConstraint)
        self._linearDragConstraint = nil
    end
end

function Disc:removeRotaryDragConstraint()
    if self._rotDragConstraint then
        World.space:removeConstraint(self._rotDragConstraint)
        self._rotDragConstraint = nil
    end
end

function Disc:removeDampedSpringConstraint()
    if self._dampedSpringConstraint then World.space:removeConstraint(self._dampedSpringConstraint) end
    self._dampedSpringConstraint = nil
end


-- update linear fluid drag and linear friction against the floor play surface
function Disc:updateDrag()
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

function Disc:enablePositionCrank()
    if self.isControllable then
        if self._positionCrankConstraint == nil then
            self._positionCrankConstraint = chipmunk.constraint.newGearJoint(self._body, World.crankBody, 0, 1)
        end
        self:setPositionCrankForce(MaxCrankForce)
        World.space:addConstraint(self._positionCrankConstraint)
    end
end

function Disc:setPositionCrankForce(force)
    if self._positionCrankConstraint ~= nil then
        self._positionCrankConstraint:setMaxBias(2 * force)
        self._positionCrankConstraint:setMaxForce(force)
    end
end

function Disc:enableTorqueCrank()
    if self.isControllable then
        self.isTorqueCrankable = true
    end
end

function Disc:disablePositionCrank()
    if self._positionCrankConstraint ~= nil then
        World.space:removeConstraint(self._positionCrankConstraint)
        self._positionCrankConstraint = nil
    end
end

function Disc:disableTorqueCrank()
    self.isTorqueCrankable = false
end

function Disc:applyTorqueCrank(t)
    if not self.isTorqueCrankable or not self.isControllable then
        return
    end
    if tonumber(t) ~= nil then
        local currentTorque = self._body:getTorque()
        self._body:setTorque(t + currentTorque)
    end
end

function Disc:toggleControl()
    self:markDirty()
    self.isControllable = not self.isControllable
    if (self.isControllable) then
        print("Enabling control on disc")
    else
        print("Disabling control on disc")
    end
end

function Disc:setEdgeFriction(frictionCoeff)
    if frictionCoeff > 0 then
        self._shape:setFriction(frictionCoeff)
    end
end

function Disc:__gc()
    print("destroying disc")
    self:removeLinearDragConstraint()
    self:removeRotaryDragConstraint()
    self:removeDampedSpringConstraint()
    self:disablePositionCrank()
    self:disableTorqueCrank()
    World.space:removeBody(self._body)
    Disc.super.__gc(self)
end
