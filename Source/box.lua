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
    self:moveTo(x, y)


    --friction
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

    print("New box " .. width .. "x" .. height .. " at (" .. x .."," .. y ..")")
end

function Box:addSprite()
    Box.super.addSprite(self)
    World.space:addShape(self._shape)
    World.space:addBody(self._body)
    if self._linearDragConstraint then World.space:addConstraint(self._linearDragConstraint) end
    if self._rotDragConstraint then World.space:addConstraint(self._rotDragConstraint) end
   print("Box:addSprite()")
end

function Box:removeSprite()
    World.space:removeShape(self._shape)
    Box.super.removeSprite(self)
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
        self:setSize(aabbWidth, aabbHeight)
    end
end

function Box:updateLinearDrag()
    if (self._linearDragConstraint ~= nil) then
        local drag = 0
        local friction = 0
        local crossSection = (self.startingWidth + self.startingHeight) / 2 --fixme: width at rotation - velocity
        local vx, vy = self._body:getVelocity()
        local w = self._body:getAngularVelocity()
        --viscous drag = dragCoeff * frontal area * v^2; 
        drag = self.dragCoeff * 2 * crossSection * (vx*vx + vy*vy)
        local frictionCoeff = self.stiction
        if (vx ~=0 or vy ~= 0 or w ~= 0) then
            frictionCoeff = self.sliction
        end
        --Coulomb drag = coefficient of friction * normal force
        friction = frictionCoeff * math.abs(World.gravity.z) * self.mass --abs: assuming same friction on screen front/back surfaces
        self._linearDragConstraint:setMaxForce(drag + friction)
    end
end

function Box:updateRotationalDrag()
    if self._rotDragConstraint ~= nil then
        local frictionCoeff = self.stiction
        local vx, vy = self._body:getVelocity()
        local w = self._body:getAngularVelocity()
        local avgRadius = (self.startingWidth + self.startingHeight) / 2
        if (vx ~=0 or vy ~= 0 or w ~= 0) then
            frictionCoeff = self.sliction
        end
        local friction = 0
        -- FIXME: circle is  2/3 coefficient of friction * normal force * radius
        friction = 0.6667 * frictionCoeff * math.abs(World.gravity.z) * self.mass * avgRadius
        self._rotDragConstraint:setMaxForce(friction)
        --TODO: viscous drag?
    end
end

function Box:draw()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillPolygon(self.polygon)
end

function Box:__gc()
    self:removeSprite()
    Box.super.__gc(self)
end