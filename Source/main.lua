local gfx = playdate.graphics

gfx.setColor(gfx.kColorBlack)

local world_setup = false
local space = nil

-- placeholder proof of life
function playdate.update() 
    if not world_setup then
        setup()
    end
    gfx.fillRect(0,0,400,240)
    playdate.drawFPS(0,0)
end

function setup()
    space = chipmunk.space.new()
    space:setGravity(0, 0.03)
    space:step(0.02)
    gravX, gravY = space:getGravity()
    print("Gravity is (", gravX, ",", gravY, ")")
    world_setup = true
end