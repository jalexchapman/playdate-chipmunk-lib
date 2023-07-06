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

function Settings.disablePositionCrank()
    for _, item in ipairs(DynamicObjects) do
        if item.disablePositionCrank ~= nil then
            item:disablePositionCrank()
        end
    end
end

function Settings.disableTorqueCrank()
    for _, item in ipairs(DynamicObjects) do
        if item.disableTorqueCrank ~= nil then
            item:disableTorqueCrank()
        end
    end
end

function Settings.enablePositionCrank()
    for _, item in ipairs(DynamicObjects) do
        if item.enablePositionCrank ~= nil then
            item:enablePositionCrank()
        end
    end
end

function Settings.enableTorqueCrank()
    for _, item in ipairs(DynamicObjects) do
        if item.enableTorqueCrank ~= nil then
            item:enableTorqueCrank()
        end
    end
end


function Settings.menuSetup()
    local menu = playdate.getSystemMenu()
    menu:addOptionsMenuItem("mode", {"const", "edit", "crank1", "crank2"}, "const", 
    function(value)
        if value == "const" then
            Settings.inputMode = InputModes.setConstants
            Settings.disablePositionCrank()
            Settings.disableTorqueCrank()
        elseif value == "edit" then
            Settings.inputMode = InputModes.editObjects
            Settings.disablePositionCrank()
            Settings.disableTorqueCrank()
        elseif value == "crank1" then
            Settings.inputMode = InputModes.positionCrank
            Settings.enablePositionCrank()
            Settings.disableTorqueCrank()
        elseif value == "crank2" then
            Settings.inputMode = InputModes.torqueCrank
            Settings.disablePositionCrank()
            Settings.enableTorqueCrank()
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
            else
                item:removeDragConstraints()
            end
        end
    end)
end