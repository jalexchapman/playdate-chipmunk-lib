import "main.lua"

InputModes = {
    setConstants = 1,
    editObjects = 2,
    positionCrank = 3,
    torqueCrank = 4
}

Settings = {
    dragEnabled = false,
    accelEnabled = true,
    inputMode = InputModes.setConstants
}

function Settings.menuSetup()
    local menu = playdate.getSystemMenu()
    menu:addOptionsMenuItem("mode", {"const", "edit", "crank1", "crank2"}, "const", 
    function(value)
        if value == "const" then
            Settings.inputMode = InputModes.setConstants
        elseif value == "edit" then
            Settings.inputMode = InputModes.editObjects
        elseif value == "crank1" then
            Settings.inputMode = InputModes.positionCrank
        elseif value == "crank2" then
            Settings.inputMode = InputModes.torqueCrank
        end
    end)
    menu:addCheckmarkMenuItem("tilt", true, function(value)
        Settings.accelEnabled = value
        if not value then
            World:setGravity(0,1,0)
        end
    end)
    menu:addCheckmarkMenuItem("drag", false, function(value)
        Settings.dragEnabled = value --FIXME: add and remove drag constraint
        for _, item in ipairs(DynamicObjects) do
            if value then
                item:addDragConstraints()
                item:enableDragConstraints()
            else
                item:removeDragConstraints()
            end
        end
    end)
end