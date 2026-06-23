--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-----------------------
--  Macro shortcuts  --
-----------------------

-- Hotkey bindings (these block the original input)

local hyper = {"cmd", "shift"}
directshyper = hs.hotkey.bind(hyper, "H", function()
    spawnPluginMenu()
end)

-- Cheatsheet overlay: Cmd+Shift+/
hs.hotkey.bind(hyper, "/", function()
    require("ui.cheatsheet").toggle()
end)

-- AI chat assistant: Cmd+Shift+A
hs.hotkey.bind(hyper, "A", function()
    require("ai.chat").toggle()
end)

hs.hotkey.bind({"cmd", "alt"}, "S", function() end)

-- buplicate shortcut
local BUPLICATE_COUNT_FIRST = 7
local BUPLICATE_COUNT_NEXT = 8

buplicate = hs.hotkey.bind({"cmd"}, "B", function()
    local count = BUPLICATE_COUNT_FIRST
    if buplicatelastshortcut == 1 then
        count = BUPLICATE_COUNT_NEXT
    end
    for _ = 1, count do
        selectLiveMenuItem("Duplicate")
    end
    buplicatelastshortcut = 1
end)

-------------------------------------------------------
--  Eventtap dispatch table for keyboard macros      --
--                                                   --
--  Instead of checking 25+ if-statements per event, --
--  we use O(1) keycode lookup + cached modifiers.   --
-------------------------------------------------------

_G.debounce = false
local down12, down22 = false, true
local press12, press22
local scaling = 0

-- Pre-compute FabFilter scaling ratios as lookup table
local FABFILTER_UNDO_FRACTIONS = {
    [string.format("%.4f", 2.0512820512821)] = 13 / 30,  -- mini
    [string.format("%.4f", 1.6112266112266)] = 12 / 30,  -- small
    [string.format("%.4f", 1.6187050359712)] = 12 / 31,  -- medium
    [string.format("%.4f", 1.625)]           = 12 / 30,  -- large
    [string.format("%.4f", 1.6304347826087)] = 12 / 29,  -- extra large
}

local FABFILTER_REDO_FRACTIONS = {
    [string.format("%.4f", 2.0512820512821)] = 14 / 30,
    [string.format("%.4f", 1.6112266112266)] = 13 / 30,
    [string.format("%.4f", 1.6187050359712)] = 13 / 31,
    [string.format("%.4f", 1.625)]           = 12 / 28,
    [string.format("%.4f", 1.6304347826087)] = 13 / 30,
}

local function handleFabFilterUndoRedo(fractionTable)
    if scaling ~= 0 then return end
    local focusedWin = hs.window.focusedWindow()
    if not focusedWin then return end
    local windowname = focusedWin:title()
    if string.lower(string.gsub(windowname, "(.*)/.*$", "%1")) ~= "fabfilter pro-q 3" then return end

    local windowframe = focusedWin:frame()
    local prepoint = hs.mouse.absolutePosition()
    local quotient = string.format("%.4f", windowframe.w / windowframe.h)
    local fraction = fractionTable[quotient]

    if fraction == nil then
        HSMakeAlert(programName, L("macros_scaling_error"), true, "warning")
        scaling = 1
        return
    end

    local postpoint = {}
    postpoint["x"] = windowframe.x + (windowframe.w * fraction)
    postpoint["y"] = windowframe.y + titlebarheight() + 20
    hs.eventtap.leftClick(postpoint, 0)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], postpoint):post()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
end

-- Individual macro handler functions

local function handleDisableLoop(mods)
    if _G.disableloop ~= 1 then return end
    if mods.shift and mods.cmd then
        hs.eventtap.keyStroke({"cmd", "shift"}, "J")
    end
end

local function handleMiddleClick(mods)
    if mods.alt then
        local point = hs.mouse.absolutePosition()
        hs.eventtap.middleClick(point, 0)
    end
end

local function handleEnvelopeMode(mods)
    if not mods.alt then return end
    _G.dimensions = getLiveHsAppObj():mainWindow():frame()
    local prepoint = hs.mouse.absolutePosition()
    prepoint["__luaSkinType"] = nil

    local postpoint = {}
    postpoint["x"] = _G.dimensions.x + 43
    postpoint["y"] = _G.dimensions.y + _G.dimensions.h - 37
    for _ = 1, 5 do
        hs.eventtap.leftClick(postpoint, 0)
        postpoint["x"] = postpoint["x"] + 18
        postpoint["y"] = postpoint["y"] - 18
    end
    postpoint["x"] = _G.dimensions.x + 51
    postpoint["y"] = _G.dimensions.y + _G.dimensions.h - 47
    hs.eventtap.leftClick(postpoint, 0)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
end

local function handleSaveAsNewVersion(mods)
    if _G.saveasnewver ~= 1 then return end
    if not (mods.alt and mods.cmd) then return end
    if _G.debounce then return end

    _G.debounce = true
    local mainwindowname = getLiveHsAppObj():mainWindow():title()
    local projectname = mainwindowname:gsub("%s%s%[.*", "")
    local newname

    if projectname == "Untitled" then
        if astBlockingQuery(programName,
            [[Your project name is "Untitled"\nAre you sure you want to save it as a new version?]]
        ) == true then
            hs.eventtap.keyStroke({"cmd", "shift"}, "S")
            hs.timer.doAfter(2, function() _G.debounce = false end)
            return
        end
    end

    -- Parse a trailing "_<version>" robustly: base is everything before the
    -- final underscore, ver is a run of digits/dots plus an optional alpha
    -- suffix (e.g. "1.5b"). Strip the letters before tonumber(); only do
    -- arithmetic once it confirms the cleaned value is numeric, else fall back.
    local base, ver = projectname:match("^(.*)_([%d%.]+%a*)$")
    local clean = ver and (ver:gsub("%a", ""))
    local vernum = base and tonumber(clean)
    if base and vernum then
        -- A dotted version (e.g. 1.5) rounds up; an integer increments by one.
        local newver = clean:find("%.") and math.ceil(vernum) or math.floor(vernum + 1)
        newname = base .. "_" .. newver
    else
        newname = projectname .. "_2"
    end

    selectLiveMenuItem("Save Live Set As")
    -- Non-blocking: wait for Save dialog to appear, then type name and confirm
    hs.timer.doAfter(0.18, function()
        hs.eventtap.keyStrokes(newname)
        hs.eventtap.keyStroke({}, "return")
        hs.timer.doAfter(2.5, function() _G.debounce = false end)
    end)
end

local function handleCloseWindow(mods)
    if _G.enableclosewindow == 0 then return end
    if not mods.cmd then return end

    if not mods.alt then
        local mainwin = getLiveHsAppObj():mainWindow()
        local focused = hs.window.frontmostWindow()
        if mainwin ~= focused then focused:close() end
    end
end

--- Close all plugin windows (not the main window).
local function closeAllPluginWindows()
    local allwindows = getLiveHsAppObj():allWindows()
    local mainwin = getLiveHsAppObj():mainWindow()
    for i = 1, #allwindows do
        if allwindows[i] ~= mainwin then allwindows[i]:close() end
    end
end

local function handleCloseAllWindows(mods)
    if _G.enableclosewindow == 0 then return end
    if mods.cmd and mods.alt then
        closeAllPluginWindows()
    end
end

local function handleCloseAllEscape(mods)
    if _G.enableclosewindow == 0 then return end
    if mods.cmd then
        closeAllPluginWindows()
    end
end

local function handleMarker(mods, eventtype)
    if eventtype ~= hs.eventtap.event.types.keyDown then return end
    if altgrmarker == 1 then
        if mods.alt and not mods.cmd then
            selectLiveMenuItem("Add Locator")
            hs.eventtap.keyStroke({}, "delete", 0)
        end
    else
        if mods.shift then
            selectLiveMenuItem("Add Locator")
            hs.eventtap.keyStroke({}, "delete", 0)
        end
    end
end

local function handleAbsoluteDuplicate(mods, eventtype)
    if _G.absolutereplace == 0 then return end
    if eventtype ~= hs.eventtap.event.types.keyUp then return end
    local match = false
    if ctrlabsoluteduplicate == 1 then
        match = mods.ctrl and mods.cmd
    else
        match = mods.alt and mods.cmd
    end
    if match then
        selectLiveMenuItem("Copy")
        selectLiveMenuItem("Duplicate")
        selectLiveMenuItem("Delete")
        selectLiveMenuItem("Paste")
    end
end

local function handleAbsoluteReplace(mods, eventtype)
    if _G.absolutereplace == 0 then return end
    if eventtype ~= hs.eventtap.event.types.keyUp then return end
    if mods.alt and mods.cmd then
        selectLiveMenuItem("Paste")
        selectLiveMenuItem("Delete")
        selectLiveMenuItem("Paste")
    end
end

local function handleDoubleZeroDelete(mods)
    if _G.double0todelete ~= 1 then return end
    if down12 == false and down22 == true then
        press12 = hs.timer.secondsSinceEpoch()
        down12, down22 = true, false
        if press22 and (press12 - press22) < 0.05 then
            hs.eventtap.keyStroke({}, hs.keycodes.map["delete"], 0)
            press12, press22 = nil, nil
        end
    elseif down12 == true and down22 == false then
        press22 = hs.timer.secondsSinceEpoch()
        down12, down22 = false, true
        if press12 and (press22 - press12) < 0.05 then
            hs.eventtap.keyStroke({}, hs.keycodes.map["delete"], 0)
            press12, press22 = nil, nil
        end
    end
end

local function handleClearTrack(mods, eventtype)
    if not mods.alt or eventtype ~= hs.eventtap.event.types.keyDown then return end
    timeRMBTime, firstDown, secondDown = nil, false, true
    firstRightClick:stop()
    local point = hs.mouse.absolutePosition()
    point["__luaSkinType"] = nil
    hs.eventtap.rightClick(point, 0)
    for _ = 1, 12 do hs.eventtap.keyStroke({}, "down", 0) end
    hs.eventtap.keyStroke({}, "return", 0)
    hs.eventtap.keyStroke({}, "delete", 0)
    firstRightClick:start()
end

local function handleColorTrack(mods, eventtype)
    if not mods.alt or eventtype ~= hs.eventtap.event.types.keyDown then return end
    timeRMBTime, firstDown, secondDown = nil, false, true
    firstRightClick:stop()
    local point = hs.mouse.absolutePosition()
    point["__luaSkinType"] = nil
    hs.eventtap.rightClick(point, 0)
    hs.eventtap.keyStroke({}, "up", 0)
    hs.eventtap.keyStroke({}, "up", 0)
    hs.eventtap.keyStroke({}, "return", 0)
    firstRightClick:start()
end

local function handleVstUndo(mods, eventtype)
    if vstshortcuts ~= 1 then return end
    if eventtype ~= hs.eventtap.event.types.keyDown then return end
    if mods.cmd and not mods.shift then
        handleFabFilterUndoRedo(FABFILTER_UNDO_FRACTIONS)
    end
end

local function handleVstRedo(mods, eventtype)
    if vstshortcuts ~= 1 then return end
    if eventtype ~= hs.eventtap.event.types.keyDown then return end
    if mods.cmd and mods.shift then
        handleFabFilterUndoRedo(FABFILTER_REDO_FRACTIONS)
    end
end

---@type table<number, fun(mods: table, eventtype: number)[]>
local keyDispatch = {}

local function registerKey(keyName, handler)
    local code = hs.keycodes.map[keyName]
    if code then
        if not keyDispatch[code] then keyDispatch[code] = {} end
        table.insert(keyDispatch[code], handler)
    end
end

-- Register all handlers (order matters for same-key handlers)
registerKey("M", handleDisableLoop)
registerKey("G", handleMiddleClick)
registerKey("E", handleEnvelopeMode)
registerKey("S", handleSaveAsNewVersion)
registerKey("W", handleCloseWindow)
registerKey("W", handleCloseAllWindows)
registerKey("L", handleMarker)
registerKey("D", handleAbsoluteDuplicate)
registerKey("V", handleAbsoluteReplace)
registerKey("0", handleDoubleZeroDelete)
registerKey("X", handleClearTrack)
registerKey("C", handleColorTrack)
registerKey("Z", handleVstUndo)
registerKey("Z", handleVstRedo)
-- escape for close-all-windows
registerKey("escape", handleCloseAllEscape)

_G.quickmacro = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp,
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseUp
}, function(event)
    local keycode = event:getKeyCode()
    local eventtype = event:getType()

    -- Reset buplicate state on non-B key or mouse click
    if keycode ~= hs.keycodes.map["B"] or
        (eventtype == hs.eventtap.event.types.leftMouseDown and buplicatelastshortcut == 1) then
        buplicatelastshortcut = 0
    end

    -- O(1) dispatch: look up handlers by keycode
    local handlers = keyDispatch[keycode]
    if handlers then
        -- Cache modifiers ONCE per event instead of 28+ times
        local mods = hs.eventtap.checkKeyboardModifiers()
        for _, handler in ipairs(handlers) do
            -- Guard each handler: an error inside (e.g. handleSaveAsNewVersion)
            -- must not strand _G.debounce = true, which would dead-lock the macro.
            local ok, err = pcall(handler, mods, eventtype)
            if not ok then
                _G.debounce = false
                print("[macros] handler error: " .. tostring(err))
            end
        end
    end
end):start()

_G.pausebutton = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(event)
    local keycode = event:getKeyCode()
    local eventtype = event:getType()

    if keycode == hs.keycodes.map["1"] and eventtype == hs.eventtap.event.types.keyDown then
        local mods = hs.eventtap.checkKeyboardModifiers()
        if mods.cmd and mods.shift then
            if threadsenabled == true then
                disablemacros()
                appwatcher:stop()
                -- Show paused HUD (stays longer to indicate persistent state)
                if showStatusHUD      then showStatusHUD("paused", 3.0) end
                if updateMenuBarState then updateMenuBarState("paused")  end
            else
                enablemacros()
                appwatcher:start()
                -- showStatusHUD("active") is already called inside enablemacros()
            end
        end
    end
end):start()
