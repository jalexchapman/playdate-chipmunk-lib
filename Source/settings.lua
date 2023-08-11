import "main.lua"

InputModes = {
    setConstants = 1,
    editObjects = 2,
    positionCrank = 3,
    torqueCrank = 4
}

Settings = {
    linearDragEnabled = false,
    rotaryDragEnabled = false,
    updateDragEveryChipmunkStep = true,
    dampedSpringsEnabled = false,
    inputMode = InputModes.setConstants
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
    menu:addOptionsMenuItem("mode", {"constants", "edit", "pos crank", "tq. crank"}, "constants", 
    function(value)
        if Settings.inputMode == InputModes.positionCrank then
            Settings.disablePositionCrank()
        elseif Settings.inputMode == InputModes.torqueCrank then
            Settings.disableTorqueCrank()
        elseif Settings.inputMode == InputModes.editObjects then
            Settings.disableEditor()
        end
        if value == "constants" then
            Settings.inputMode = InputModes.setConstants
        elseif value == "edit" then
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
    menu:addOptionsMenuItem("friction", {"off", "linear", "rotary", "both", "both2", "spring"}, "off",
    function(value)
        if value == "linear" or value == "both" or value == "both2" then
            Settings.linearDragEnabled = true
        else
            Settings.linearDragEnabled = false
        end
        if value == "rotary" or value == "both" or value == "both2" then
            Settings.rotaryDragEnabled = true
        else
            Settings.rotaryDragEnabled = false
        end
        if value == "both2"  then
            Settings.updateDragEveryChipmunkStep = false
        else
            Settings.updateDragEveryChipmunkStep = true
        end
        if value == "spring" then
            Settings.dampedSpringsEnabled = true
        else
            Settings.dampedSpringsEnabled = false
        end
        for _, item in ipairs(DynamicObjects) do
            if Settings.linearDragEnabled then
                item:addLinearDragConstraint()
            else
                item:removeLinearDragConstraint()
            end
            if Settings.rotaryDragEnabled then
                item:addRotaryDragConstraint()
            else
                item:removeRotaryDragConstraint()
            end
            if Settings.dampedSpringsEnabled then
                item:addDampedSpringConstraint()
            else
                item:removeDampedSpringConstraint()
            end
        end
    end)
end