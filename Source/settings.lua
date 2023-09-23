import "main.lua"

InputModes = {
    torqueCrank = 1,
    positionCrank = 2,
    editObjects = 3
}

Settings = {
    dragEnabled = false,
    updateDragEveryChipmunkStep = true,
    inputMode = InputModes.torqueCrank
}

function Settings.disablePositionCrank()
    for _, item in ipairs(DynamicObjects) do
        if item.disablePositionCrank ~= nil then
            item:disablePositionCrank()
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

function Settings.disableTorqueCrank()
    for _, item in ipairs(DynamicObjects) do
        if item.disableTorqueCrank ~= nil then
            item:disableTorqueCrank()
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

function Settings.disableEditor()
    playdate.display.setRefreshRate(0)
    EditorSprite:removeSprite()
end

function Settings.enableEditor()
    playdate.display.setRefreshRate(30) -- be nice to the battery when we can
    EditorSprite:addSprite()
end

function Settings.menuSetup()
    local menu = playdate.getSystemMenu()
    menu:addOptionsMenuItem("mode", {"tq. crank", "pos crank",  "edit"}, "constants", 
    function(value)
        if Settings.inputMode == InputModes.positionCrank then
            Settings.disablePositionCrank()
        elseif Settings.inputMode == InputModes.torqueCrank then
            Settings.disableTorqueCrank()
        elseif Settings.inputMode == InputModes.editObjects then
            Settings.disableEditor()
        end
        if value == "edit" then
            Settings.inputMode = InputModes.editObjects
            Settings.enableEditor()
        elseif value == "pos crank" then
            Settings.inputMode = InputModes.positionCrank
            Settings.enablePositionCrank()
        elseif value == "tq. crank" then
            Settings.inputMode = InputModes.torqueCrank
            Settings.enableTorqueCrank()
        end
    end)
    menu:addOptionsMenuItem("surf. drag", {"off", "on", "fast"}, "off",
    function(value)
        if value == "on" or value == "fast" then
            Settings.dragEnabled = true
        else
            Settings.dragEnabled = false
        end
        if value == "fast"  then
            Settings.updateDragEveryChipmunkStep = false
        else
            Settings.updateDragEveryChipmunkStep = true
        end
        for _, item in ipairs(DynamicObjects) do
            if Settings.dragEnabled then
                item:addLinearDragConstraint()
                item:addRotaryDragConstraint()
            else
                item:removeLinearDragConstraint()
                item:removeRotaryDragConstraint()
            end
        end
    end)
end