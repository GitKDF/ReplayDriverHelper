-- Persistent Settings
local settings = ac.storage{
    showWindow = true            -- Saved between sessions
}

-- State Tracking
local lastFocusedCar = -1
local inReplay = false
local replaySwitch = false

-- Debug States
local debugEnabled = false
local debugLine = 1

local function RDHDebug(output)
    if debugEnabled then
        ac.debug(tostring(debugLine) .. ": " .. tostring(output))
        debugLine = debugLine + 1
    end
end

------------------------------------------------------------
-- UPDATE LOGIC (runs every frame)
------------------------------------------------------------
function script.update(dt)
    local sim = ac.getSim()

    -- Check if we should hide or show window
    local win = ac.accessAppWindow('IMGUI_LUA_ReplayDriverHelper_main')
    if win and win:valid() then
        if not inReplay then
            if sim.isReplayActive then
                RDHDebug("Replay started, showing window = " .. tostring(settings.showWindow))
                inReplay = true
                if not win:visible() then
                    win:setVisible(settings.showWindow)
                end
            else
                inReplay = false
                if win:visible() then
                    RDHDebug("Replay ended, hiding window")
                    replaySwitch = true
                    win:setVisible(false)
                    return
                end
            end
        else
            if not sim.isReplayActive then
                inReplay = false
            end
        end
    end

    -- Detect when the focused car changes
    local currentCar = sim.focusedCar
    if currentCar ~= lastFocusedCar then
        lastFocusedCar = currentCar
        RDHDebug("Focused car changed to " .. tostring(currentCar))
    end
end

------------------------------------------------------------
-- MAIN WINDOW (new‑mode UI)
------------------------------------------------------------
function windowMain()
    local sim = ac.getSim()
    if not inReplay then return end
    if not settings.showWindow then return end

    ui.text("Click to focus driver:")
    ui.separator()

    ui.beginChild("scrollList", vec2(0, 0), true)

    for i = 0, sim.carsCount - 1 do
        local car = ac.getCar(i)
        if car and car.isConnected then
            local name = ac.getDriverName(i)
            if name and name ~= "" then

                local isFocused = (i == sim.focusedCar)

                if isFocused then
                    ui.pushStyleColor(ui.StyleColor.Header,        rgbm(1, 1, 0, 0.4))
                    ui.pushStyleColor(ui.StyleColor.HeaderHovered, rgbm(1, 1, 0, 0.5))
                    ui.pushStyleColor(ui.StyleColor.HeaderActive,  rgbm(1, 1, 0, 0.6))
                end

                if ui.selectable(string.format("%02d. %s", i + 1, name), isFocused) then
                    ac.focusCar(i)
                    -- AC replay UI will NOT update driver number; this is unfortunate, but normal.
                end

                if isFocused then
                    ui.popStyleColor(3)
                end
            end
        end
    end

    ui.endChild()
end

------------------------------------------------------------
-- SHOW / HIDE CALLBACKS (CSP calls these automatically)
------------------------------------------------------------
function showRDH(dt)
    settings.showWindow = true
    RDHDebug("Show  " .. tostring(settings.showWindow))
end

function hideRDH(dt)
    if not replaySwitch then
        settings.showWindow = false
        RDHDebug("Hide  " .. tostring(settings.showWindow))
    else
        replaySwitch = false
        RDHDebug("Hide ignored due to replaySwitch")
    end
end
