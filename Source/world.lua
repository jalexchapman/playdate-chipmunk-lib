World = {}
World.space = nil
World.staticBody = nil
World.minGravity = 0
World.maxGravity = 66778 -- 9.8 m/s^2 at 173ppi (6811 px/m)
World._gravityMagnitude = 16000 -- feels a bit more comfortable
World._tiltEnabled = true
World.stiction = 0.3
World.sliction = 0.25
World.dragCoeff = 0.0015

function World:setup()
    if self.space ~= nil then return end
    self.space = chipmunk.space.new()
    self.staticBody = self.space:getStaticBody()
    self.space:setDamping(1.0) -- no damping    
    self.gravity = {x=0, y=0, z=0}
    self.crankBody = chipmunk.body.newKinematic()
    self.space:addBody(self.crankBody) -- this body represents the crank angle/velocity
end

function World:getGravityMagnitude()
    return self._gravityMagnitude
end

function World:setGravityMagnitude(value)
    if tonumber(value) then
        if value < World.minGravity then value = World.minGravity end
        if value > World.maxGravity then value = World.maxGravity end
        if value ~= World._gravityMagnitude then
            self._gravityMagnitude = value
            if not self._tiltEnabled then
                -- make sure space:setGravity gets poked
                self:setAccelVector(0,1,0)
            end
        end
    end
end

function World:setTiltEnabled(value)
    if not value then
        self._tiltEnabled = false -- effectively coerce to boolean
        playdate.stopAccelerometer()
        self:setAccelVector(0,1,0)
    else
        self._tiltEnabled = true
        playdate.startAccelerometer()
    end
end

function World:isTiltEnabled()
    return self._tiltEnabled
end

-- Set gravity direction and magnitude relative to maxGravity:
-- (0,1,0) would be 1g straight down.
-- Values are not normalized, because the device may be accelerating.
function World:setAccelVector(x, y, z)
    x = x * World._gravityMagnitude
    y = y * World._gravityMagnitude
    z = z * World._gravityMagnitude
    self.gravity.x = x
    self.gravity.y = y
    self.gravity.z = z -- cpSpace doesn't know about Z but other classes may consume this, like world friction
    if self.space ~= nil then
        self.space:setGravity(x, y)
    end
end