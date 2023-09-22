import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "World"

local gfx = playdate.graphics
local geom = playdate.geometry

class('Box').extends(gfx.sprite)

function Box:init(x, y, width, height, cornerRadius, density, friction, elasticity)
    Box.super.init(self)

    self.dragCoeff = .0015
    self.stiction = 0.3
    self.sliction = 0.25

    local mass = width * height * density
    local moment = chipmunk.momentForBox(mass, width, height)
    local body = chipmunk.body.newDynamic(mass, moment)
    body:setPosition(x, y)

    self.angle = 0
    self.density = density
    self.friction = friction
    self.elasticity = elasticity
    self.angle = angle
    self._body = body
    self.mass = mass
    self.moment = moment

    self.prevX = x
    self.prevY = y
    self.prevAngle = self.angle

    self.startingWidth = width
    self.startingHeight = height
    local halfwidth = width/2
    local halfheight = height/2
    self.startingPolygon = geom.polygon.new(
        -1 * halfwidth, -1 * halfheight,
        halfwidth, -1 * halfheight,
        halfwidth, halfheight,
        -1 * halfwidth, halfheight,
        -1 * halfwidth, -1 * halfheight
    )

    self.rotationTransform = geom.affineTransform.new()
    self.polygon = self.startingPolygon * self.rotationTransform
    self.polygon:translate(halfwidth, halfheight)


    self._shape = chipmunk.shape.newBox(
        self._body,
        width - 2 * cornerRadius, 
        height - 2 * cornerRadius, 
        cornerRadius)

    self._shape:setFriction(friction)
    self._shape:setElasticity(elasticity)

    
    --gfx.sprite stuff
    self:setSize(width, height)
    self:setCenter(0.5, 0.5)
    self:setCollideRect(0, 0, width, height)
    self:moveTo(x, y)

    self.pattern = {0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff}

    World.space:addShape(self._shape)
    World.space:addBody(self._body)

    self.isControllable = false
    self.isTorqueCrankable = false

    if Settings.dragEnabled then
        self:addLinearDragConstraint()
        self:addRotaryDragConstraint()
    end
    if Settings.inputMode == InputModes.positionCrank then
        self:enablePositionCrank()
    end
    self:addSprite()
end

function Box:addLinearDragConstraint()
    if not self._linearDragConstraint then
        local linearDragConstraint = chipmunk.constraint.newPivotJoint(self._body, World.staticBody, 0, 0, 0, 0)
        if linearDragConstraint ~= nil then
            linearDragConstraint:setMaxBias(0) -- we don't actually want to pivot
            linearDragConstraint:setMaxForce(0) -- update will set this
            World.space:addConstraint(linearDragConstraint)
        end
        self._linearDragConstraint = linearDragConstraint
    end
end

function Box:addRotaryDragConstraint()
    if not self._rotDragConstraint then
        local rotDragConstraint = chipmunk.constraint.newGearJoint(self._body, World.staticBody, 0, 1)
        if rotDragConstraint ~= nil then
            rotDragConstraint:setMaxBias(0)
            rotDragConstraint:setMaxForce(0)
            World.space:addConstraint(rotDragConstraint)
        end
        self._rotDragConstraint = rotDragConstraint
    end
end

function Box:addDampedSpringConstraint()
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


function Box:removeLinearDragConstraint()
    if self._linearDragConstraint then World.space:removeConstraint(self._linearDragConstraint) end
    self._linearDragConstraint = nil
end

function Box:removeRotaryDragConstraint()
    if self._rotDragConstraint then World.space:removeConstraint(self._rotDragConstraint) end
    self._rotDragConstraint = nil
end

function Box:removeDampedSpringConstraint()
    if self._dampedSpringConstraint then World.space:removeConstraint(self._dampedSpringConstraint) end
    self._dampedSpringConstraint = nil
end

function Box:enablePositionCrank()
    if self.isControllable then
        if self._positionCrankConstraint == nil then
            self._positionCrankConstraint = chipmunk.constraint.newGearJoint(self._body, World.crankBody, 0, 1)
        end
        self:setPositionCrankForce(MaxCrankForce)
        World.space:addConstraint(self._positionCrankConstraint)
    end
end

function Box:setPositionCrankForce(force)
    if self._positionCrankConstraint ~= nil then
        self._positionCrankConstraint:setMaxBias(2 * force)
        self._positionCrankConstraint:setMaxForce(force)
    end
end

function Box:disablePositionCrank()
    if self._positionCrankConstraint ~= nil then
        World.space:removeConstraint(self._positionCrankConstraint)
        self._positionCrankConstraint = nil
    end
end

function Box:enableTorqueCrank()
    if self.isControllable then
        self.isTorqueCrankable = true
    end
end

function Box:disableTorqueCrank()
    self.isTorqueCrankable = false
end

function Box:applyTorqueCrank(t)
    if not self.isTorqueCrankable or not self.isControllable then
        return
    end
    if tonumber(t) ~= nil then
       local currentTorque = self._body:getTorque()
        self._body:setTorque(t + currentTorque)
    end
end

function Box:toggleControl()
    self:markDirty()
    self.isControllable = not self.isControllable
    if (self.isControllable) then
        print("Enabling control on box")
    else
        print("Disabling control on box")
    end
end

function Box:setEdgeFriction(frictionCoeff)
    if frictionCoeff >= 0 then
        self._shape:setFriction(frictionCoeff)
    end
end

function Box:getEdgeFriction(frictionCoeff)
    return self._shape:getFriction()
end

function Box:setElasticity(e)
    if e >= 0 then
        self._shape:setElasticity(e)
    end
end

function Box:getElasticity()
    return self._shape:getElasticity()
end

function Box:setDensity(d)
    if d > 0 then
        self.density = d

        local w = self.startingWidth
        local h = self.startingHeight
        local m = d * w * h
        self._body:setMass(m)
        self.mass = m

        local I = chipmunk.momentForBox(m, w, h)
        self.moment = I
        self._body:setMoment(I)
    end
end

function Box:getDensity()
    return self.density
end

function Box:update()
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
        self.rotationTransform:reset()
        self.rotationTransform:rotate(math.deg(a))
        self.polygon = self.startingPolygon * self.rotationTransform
        local _, _, aabbWidth, aabbHeight = self.polygon:getBounds()
        self.polygon:translate(aabbWidth/2, aabbHeight/2)
        self:setSize(aabbWidth + 1, aabbHeight + 1)
        self:setCollideRect(0, 0, aabbWidth, aabbHeight)
    end
end

function Box:updateDrag()
    if self._linearDragConstraint ~= nil or self._rotDragConstraint ~= nil then
        local vx, vy = self._body:getVelocity()
        local w = self._body:getAngularVelocity()
        local drag = 0
        local friction = 0
        local frictionCoeff = self.stiction * World.stiction
        if (vx ~=0 or vy ~= 0 or w ~= 0) then
            frictionCoeff = self.sliction * World.sliction
        end
        if (self._linearDragConstraint ~= nil) then
            local crossSection = (self.startingWidth + self.startingHeight) / 2 --fixme: width at rotation - velocity
            -- viscous drag = dragCoeff * frontal area * v^2; 
            drag = self.dragCoeff * 2 * crossSection * (vx*vx + vy*vy)
            -- Coulomb drag = coefficient of friction * normal force
            friction = frictionCoeff * math.abs(World.gravity.z) * self.mass --abs: assuming same friction on screen front/back surfaces
            --print("friction: " .. friction .. "  drag: " .. drag)
            self._linearDragConstraint:setMaxForce(drag + friction)
        end
        if self._rotDragConstraint ~= nil then
            local avgRadius = (self.startingWidth + self.startingHeight) / 2
            -- FIXME: circle is  2/3 coefficient of friction * normal force * radius
            friction = 0.6667 * frictionCoeff * math.abs(World.gravity.z) * self.mass * avgRadius
            self._rotDragConstraint:setMaxForce(friction)
            --TODO: viscous drag?
        end
    end
end

function Box:pointHit(p)
    local leftX, topY = self:getBounds()
    local relativeP = p:offsetBy(-leftX, -topY)
    return self.polygon:containsPoint(relativeP)
end

function Box:draw()
    local pattern = SolidPattern
    local outline = false
    if self.isControllable then 
        pattern = ControllablePattern
        outline = true
    end
    Box.drawStatic(self.polygon, pattern, gfx.kColorBlack, outline)
end

function Box.drawStatic(polygon, pattern, color, useOutline)
    gfx.setColor(color)
    gfx.setPattern(pattern)
    gfx.fillPolygon(polygon)
    gfx.setPattern(SolidPattern)
    if useOutline then
        gfx.setLineWidth(1)
        gfx.drawPolygon(polygon)
    end
end

function Box:__gc()
    print("destroying box")
    self:disablePositionCrank()
    self:removeLinearDragConstraint()
    self:removeRotaryDragConstraint()
    self:removeDampedSpringConstraint()
    World.space:removeShape(self._shape)
    World.space:removeBody(self._body)
    self:removeSprite()
    Box.super.__gc(self)
end