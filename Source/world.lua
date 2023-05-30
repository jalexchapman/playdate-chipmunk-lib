World = {}
World.space = nil
World.staticBody = nil

function World:setup()
    if self.space ~= nil then return end
    self.space = chipmunk.space.new()
    self.staticBody = self.space:getStaticBody()
    self.space:setDamping(1.0) -- no damping    
end
