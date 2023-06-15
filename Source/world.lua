World = {}
World.space = nil
World.staticBody = nil

function World:setup()
    if self.space ~= nil then return end
    self.space = chipmunk.space.new()
    self.staticBody = self.space:getStaticBody()
    self.space:setDamping(1.0) -- no damping    
    self.gravity = {x=0, y=0, z=0}
end

function World:setGravity(x, y, z)
    self.gravity.x = x
    self.gravity.y = y
    self.gravity.z = z -- cpSpace doesn't know about Z but other classes may consume this, like world friction
    if self.space ~= nil then
        self.space:setGravity(x, y)
    end
end