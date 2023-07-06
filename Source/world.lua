World = {}
World.space = nil
World.staticBody = nil
World.minGravity = 0
World.maxGravity = 66778 -- 9.8 m/s^2 at 173ppi (6811 px/m)
World.gravityMagnitude = 33289 -- feels a bit more comfortable


function World:setup()
    if self.space ~= nil then return end
    self.space = chipmunk.space.new()
    self.staticBody = self.space:getStaticBody()
    self.space:setDamping(1.0) -- no damping    
    self.gravity = {x=0, y=0, z=0}
    self.crankBody = chipmunk.body.newKinematic()
    self.space:addBody(self.crankBody) -- this body represents the crank angle/velocity
end

-- Set gravity direction and magnitude relative to maxGravity:
-- (0,1,0) would be 1g straight down.
-- Values are not normalized, because the device may be accelerating.
function World:setGravity(x, y, z)
    x = x * World.gravityMagnitude
    y = y * World.gravityMagnitude
    z = z * World.gravityMagnitude
    self.gravity.x = x
    self.gravity.y = y
    self.gravity.z = z -- cpSpace doesn't know about Z but other classes may consume this, like world friction
    if self.space ~= nil then
        self.space:setGravity(x, y)
    end
end