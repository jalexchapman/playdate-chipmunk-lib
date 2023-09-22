import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics

class('Disc').extends(gfx.sprite)

function Disc:init(x, y, radius, density, friction, elasticity)
    Disc.super.init(self)

    self.dragCoeff = .0015
    self.stiction = 0.3
    self.sliction = 0.25

    local mass = math.pi * radius^2 * density
    local moment = chipmunk.momentForCircle(mass, radius, 0, 0, 0)
    local body = chipmunk.body.newDynamic(mass, moment)
    body:setPosition(x, y)

    self.angle = 0
    self.radius = radius
    self.density = density
    self.friction = friction
    self.elasticity = elasticity
    self._body = body
    self.mass = mass
    self.moment = moment

    self.prevX = x
    self.prevY = y
    self.prevAngle = self.angle

    self._shape = chipmunk.shape.newCircle(self._body, radius, 0, 0)
    self._shape:setFriction(friction)
    self._shape:setElasticity(elasticity)

    --gfx.sprite stuff
    local diameter=  radius * 2 + 1
    self:setSize(diameter, diameter)
    self:setCenter(0.5, 0.5)
    self:setCollideRect(0, 0, diameter, diameter)
    self:moveTo(x, y)

    self.alpha = 1.0

    World.space:addBody(self._body)
    World.space:addShape(self._shape)

    self.isControllable = false
    self.isTorqueCrankable = false

    if Settings.dragEnabled then
        self:addLinearDragConstraint()
        self:addRotaryDragConstraint()
    end
    if Settings.inputMode == InputModes.torqueCrank then
        self:enableTorqueCrank()
    elseif Settings.inputMode == InputModes.positionCrank then
        self:enablePositionCrank()
    end
    self:addSprite()
end

function Disc:update()
    local a = self._body:getAngle()
    local x, y = self._body:getPosition()

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

function Disc:draw()
    local pattern = SolidPattern
    local useOutline = false
    gfx.setColor(gfx.kColorBlack)
    if self.isControllable then
        pattern = ControllablePattern
        useOutline = true
    end
    Disc.drawStatic(self.radius, self.angle, pattern, gfx.kColorBlack, useOutline)
end

function Disc.drawStatic(radius, angle, pattern, color, useOutline)
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

function Disc:pointHit(p)
    local minRadius = 4
    local squaredHitRadius = math.max(self.radius, minRadius) ^ 2
    local squaredDist = (p.x - self.x)^2 + (p.y - self.y)^2
    return squaredDist < squaredHitRadius
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
    if self._linearDragConstraint ~= nil or self._rotDragConstraint ~= nil then
        local vx, vy = self._body:getVelocity()
        local w = self._body:getAngularVelocity()
        local drag = 0
        local friction = 0
        local frictionCoeff = self.stiction
        if (vx ~=0 or vy ~= 0 or w ~= 0) then
            frictionCoeff = self.sliction
        end
        if (self._linearDragConstraint ~= nil) then
            --viscous drag = dragCoeff * frontal area * v^2; 
            drag = self.dragCoeff * 2 * self.radius * (vx*vx + vy*vy)
            --Coulomb drag = coefficient of friction * normal force
            friction = frictionCoeff * math.abs(World.gravity.z) * self.mass --abs: assuming same friction on screen front/back surfaces
            self._linearDragConstraint:setMaxForce(drag + friction)
        end
        if self._rotDragConstraint ~= nil then
            -- Torque = 2/3 coefficient of friction * normal force * radius
            friction = 0.6667 * frictionCoeff * math.abs(World.gravity.z) * self.mass * self.radius
            self._rotDragConstraint:setMaxForce(friction)
            --TODO: viscous drag?
        end
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
    if frictionCoeff >= 0 then
        self._shape:setFriction(frictionCoeff)
    end
end

function Disc:getEdgeFriction(frictionCoeff)
    return self._shape:getFriction()
end

function Disc:setElasticity(e)
    if e >= 0 then
        self._shape:setElasticity(e)
    end
end

function Disc:getElasticity()
    return self._shape:getElasticity()
end

function Disc:setDensity(d)
    if d > 0 then
        self.density = d
        local r = self.radius

        local m = math.pi * r^2 * d
        self._body:setMass(m)
        self.mass = m

        local I = chipmunk.momentForCircle(m, r, 0, 0)
        self.moment = I
        self._body:setMoment(I)
    end
end

function Disc:getDensity()
    return self.density
end

function Disc:__gc()
    print("destroying disc")
    self:disablePositionCrank()
    self:removeLinearDragConstraint()
    self:removeRotaryDragConstraint()
    self:removeDampedSpringConstraint()
    World.space:removeShape(self._shape)
    World.space:removeBody(self._body)
    self:removeSprite()
    Disc.super.__gc(self)
end
