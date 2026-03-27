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

-- this is direct's hyper. it opens the plugin menu. It's kept in for fallback purposes.
-- the difference between hs.hotkey is that it blocks the original input; hs.eventtap.event does not.

-- This is my current fallback because I cannot seem to get
-- the double right clicking working properly yet. - Direct
local hyper = {"cmd", "shift"}
directshyper = hs.hotkey.bind(hyper, "H", function()
    spawnPluginMenu()
end)

local hyper3 = {"cmd", "alt"}
hs.hotkey.bind(hyper3, "S", function()
end)

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

-- since eventtap.events seems to use quite a bit of CPU on lower end models, I've decided to try and condense a bunch of such shortcuts into this section.
-- the advantage of this approach is, unlike hs.hotkey, that it sends the original input still.
-- it also allows you to trigger actions on the key down or key up event only, which is nice.

-- I also tend to prefer tasking the menubar instead of using a cmd keystroke. There seems to be a system bound limit on how fast you can send shortcuts.
-- by using the menubar instead I'm able to bypass this somehow

_G.debounce = false
local down12, down22 = false, true
local press12, press22

local scaling = 0

_G.quickmacro = hs.eventtap.new({ -- this is the hs.eventtap event that contains all of the macro shortcuts.
hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp, hs.eventtap.event.types.leftMouseDown,
hs.eventtap.event.types.leftMouseUp}, function(event)
    local keycode = event:getKeyCode()
    local mousestate = event:getButtonState(0)
    local eventtype = event:getType()
    local clickState = hs.eventtap.event.properties.mouseEventClickState

    local backspacekk = hs.keycodes.map["delete"]

    -- macro for automatically disabling loop on clips
    if _G.disableloop == 1 then
        if keycode == hs.keycodes.map["M"] and hs.eventtap.checkKeyboardModifiers().shift and
            hs.eventtap.checkKeyboardModifiers().cmd then
            local hyper2 = {"cmd", "shfit"}
            hs.eventtap.keyStroke(hyper2, "J")
        end
    end

    if keycode == hs.keycodes.map["G"] and hs.eventtap.checkKeyboardModifiers().alt and eventtype ==
        hs.eventtap.event.types.keyDown then
        local point = hs.mouse.absolutePosition()
        hs.eventtap.middleClick(point, 0)
    end

    -- envelope mode macro
    if keycode == hs.keycodes.map["E"] and hs.eventtap.checkKeyboardModifiers().alt then
        _G.dimensions = getLiveHsAppObj():mainWindow():frame()

        -- I'm trying to use maths to consistenly figure out where the envelope button might be.
        -- I fire a laser of diagonal clicks, hoping to hit the button. I finetuned these values to the point that it works pretty well.

        local prepoint = hs.mouse.absolutePosition()
        prepoint["__luaSkinType"] = nil

        local coolvar5 = (_G.dimensions.x + 43)
        local coolvar4 = (_G.dimensions.y + _G.dimensions.h - 37)

        local postpoint = {}
        postpoint["x"] = coolvar5
        postpoint["y"] = coolvar4
        for i = 1, 5, 1 do
            hs.eventtap.leftClick(postpoint, 0)
            postpoint["x"] = postpoint["x"] + 18
            postpoint["y"] = postpoint["y"] - 18
        end
        postpoint["x"] = (_G.dimensions.x + 51)
        postpoint["y"] = (_G.dimensions.y + _G.dimensions.h - 47)
        hs.eventtap.leftClick(postpoint, 0)
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
    end

    -- save as new version
    if _G.saveasnewver == 1 then
        if keycode == hs.keycodes.map["S"] and hs.eventtap.checkKeyboardModifiers().alt and
            hs.eventtap.checkKeyboardModifiers().cmd then
            if _G.debounce == false then
                _G.debounce = true
                local hyper2 = {"cmd", "shift"}
                local mainwindowname = getLiveHsAppObj():mainWindow():title()
                local projectname = (mainwindowname:gsub("%s%s%[.*", "")) -- use Gsub to get project name from main window title
                local newname = nil

                if projectname == "Untitled" and o == nil then -- dialog box that warns you when you save as new version on an untitled project
                    if astBlockingQuery(
                        programName,
                        [[Your project name is "Untitled"\nAre you sure you want to save it as a new version?]]
                    ) == true then
                        hs.eventtap.keyStroke(hyper2, "S")
                        if astSleep(2) == true then
                            _G.debounce = false
                        end
                        return
                    end
                end

                if string.find(projectname, "_%d") then -- does the project already have a version syntax?
                    local version = (projectname:gsub(".*(.*)_", "%1")) -- remove everything after the last "_"
                    local name = (projectname:gsub("(.*)_.*", "%1")) -- remove everything prior to the last "_"

                    if string.find(version, "%.") and string.find(version, "%a") then -- test if the current version syntax has both a decimal and a letter
                        local everythingafterdecimal = version:gsub(".*%.", "") -- process things after decimal and pre decimal
                        everythingafterdecimal = everythingafterdecimal:gsub("%a", "1")
                        version = version:gsub("%..*", "." .. everythingafterdecimal)
                    end

                    local newver
                    if string.find(version, "%.") then -- if string has a decimal point, round it up
                        newver = math.ceil(version)
                    else
                        newver = (version + 1) -- if string doesn't have a decimal point, add 1
                        newver = math.floor(newver)
                    end
                    newname = name .. "_" .. newver
                else
                    newname = projectname .. "_2"
                end

                selectLiveMenuItem("Save Live Set As")

                astSleep(0.18)

                hs.eventtap.keyStrokes(newname)
                hs.eventtap.keyStroke({}, "return")

                if astSleep(2.5) == true then
                    _G.debounce = false
                end
            end
        end
    end

    -- macro for closing currently focussed plugin window
    if _G.enableclosewindow ~= 0 then
        if keycode == hs.keycodes.map["W"] and hs.eventtap.checkKeyboardModifiers().cmd and
            not hs.eventtap.checkKeyboardModifiers().alt then
            local mainwindowname = getLiveHsAppObj():mainWindow()
            local focusedWindow = hs.window.frontmostWindow()
            if mainwindowname ~= focusedWindow then
                focusedWindow:close()
            end
        end

        -- macro for closing all plugin windows
        if keycode == hs.keycodes.map["W"] and hs.eventtap.checkKeyboardModifiers().cmd and
            hs.eventtap.checkKeyboardModifiers().alt or keycode == hs.keycodes.map["escape"] and
            hs.eventtap.checkKeyboardModifiers().cmd then
            local allwindows = getLiveHsAppObj():allWindows()
            local mainwindowname = getLiveHsAppObj():mainWindow()
            for i = 1, #allwindows, 1 do
                if allwindows[i] ~= mainwindowname then
                    allwindows[i]:close()
                end
            end
        end
    end

    -- macro for adding a locator in the playlist
    if altgrmarker == 1 then
        if keycode == hs.keycodes.map["L"] and hs.eventtap.checkKeyboardModifiers().alt and eventtype ==
            hs.eventtap.event.types.keyDown and not hs.eventtap.checkKeyboardModifiers().cmd then
            print("marker macro pressed")
            selectLiveMenuItem("Add Locator")
            hs.eventtap.keyStroke({}, "delete", 0)
        end
    else
        if keycode == hs.keycodes.map["L"] and hs.eventtap.checkKeyboardModifiers().shift and eventtype ==
            hs.eventtap.event.types.keyDown then
            print("marker macro pressed")
            selectLiveMenuItem("Add Locator")
            hs.eventtap.keyStroke({}, "delete", 0)
        end
    end

    -- Absolute Duplicate
    if _G.absolutereplace ~= 0 then
        if ctrlabsoluteduplicate == 1 then
            if keycode == hs.keycodes.map["D"] and hs.eventtap.checkKeyboardModifiers().ctrl and
                hs.eventtap.checkKeyboardModifiers().cmd and eventtype == hs.eventtap.event.types.keyUp then
                selectLiveMenuItem("Copy")
                selectLiveMenuItem("Duplicate")
                selectLiveMenuItem("Delete")
                selectLiveMenuItem("Paste")
            end
        else
            if keycode == hs.keycodes.map["D"] and hs.eventtap.checkKeyboardModifiers().alt and
                hs.eventtap.checkKeyboardModifiers().cmd and eventtype == hs.eventtap.event.types.keyUp then
                selectLiveMenuItem("Copy")
                selectLiveMenuItem("Duplicate")
                selectLiveMenuItem("Delete")
                selectLiveMenuItem("Paste")
            end
        end

        if keycode == hs.keycodes.map["V"] and hs.eventtap.checkKeyboardModifiers().alt and
            hs.eventtap.checkKeyboardModifiers().cmd and eventtype == hs.eventtap.event.types.keyUp then
            selectLiveMenuItem("Paste")
            selectLiveMenuItem("Delete")
            selectLiveMenuItem("Paste")
        end
    end

    if keycode ~= hs.keycodes.map["B"] or eventtype == hs.eventtap.event.types.leftMouseDown and buplicatelastshortcut ==
        1 then
        buplicatelastshortcut = 0
    end

    if _G.double0todelete == 1 then
        if keycode == hs.keycodes.map["0"] then -- double zero to delete
            if down12 == false and down22 == true then
                press12 = hs.timer.secondsSinceEpoch()
                down12 = true
                down22 = false
                if press22 ~= nil then
                    if (press12 - press22) < 0.05 then
                        hs.eventtap.keyStroke({}, hs.keycodes.map["delete"], 0)
                        press12 = nil
                        press22 = nil
                    end
                end
            elseif down12 == true and down22 == false then
                press22 = hs.timer.secondsSinceEpoch()
                down12 = false
                down22 = true
                if press12 ~= nil then
                    if (press22 - press12) < 0.05 then
                        hs.eventtap.keyStroke({}, hs.keycodes.map["delete"], 0)
                        press12 = nil
                        press22 = nil
                    end
                end
            end
        end
    end

    -- clear track
    if keycode == hs.keycodes.map["X"] and hs.eventtap.checkKeyboardModifiers().alt and eventtype ==
        hs.eventtap.event.types.keyDown then
        if firstDown ~= nil or secondDown ~= nil then
            timeRMBTime, firstDown, secondDown = 0, false, true
        end
        firstRightClick:stop()
        local point = hs.mouse.absolutePosition()
        point["__luaSkinType"] = nil
        hs.eventtap.rightClick(point, 0)

        for _ = 1, 12 do
            hs.eventtap.keyStroke({}, "down", 0)
        end
        hs.eventtap.keyStroke({}, "return", 0)
        hs.eventtap.keyStroke({}, "delete", 0)
        firstRightClick:start()
    end

    -- colour track
    if keycode == hs.keycodes.map["C"] and hs.eventtap.checkKeyboardModifiers().alt and eventtype ==
        hs.eventtap.event.types.keyDown then
        if firstDown ~= nil or secondDown ~= nil then
            timeRMBTime, firstDown, secondDown = 0, false, true
        end
        firstRightClick:stop()
        local point = hs.mouse.absolutePosition()
        point["__luaSkinType"] = nil
        hs.eventtap.rightClick(point, 0)

        hs.eventtap.keyStroke({}, "up", 0)
        hs.eventtap.keyStroke({}, "up", 0)
        hs.eventtap.keyStroke({}, "return", 0)
        firstRightClick:start()
    end

    -- VST shortcuts within quickmacro
    if vstshortcuts == 1 then
        if keycode == hs.keycodes.map["Z"] and hs.eventtap.checkKeyboardModifiers().cmd and
            not hs.eventtap.checkKeyboardModifiers().shift and eventtype == hs.eventtap.event.types.keyDown then -- pro-q 3 undo
            local windowname = hs.window.focusedWindow():title()
            if string.lower(string.gsub(windowname, "(.*)/.*$", "%1")) == "fabfilter pro-q 3" and scaling == 0 then
                local windowframe = hs.window.focusedWindow():frame()
                local prepoint = hs.mouse.absolutePosition()
                local postpoint = {}
                local quotient = windowframe.w / windowframe.h
                quotient = string.format("%.4f", quotient)

                local fraction = nil
                if quotient == string.format("%.4f", 2.0512820512821) then -- mini scaling
                    fraction = 13 / 30
                end
                if quotient == string.format("%.4f", 1.6112266112266) then -- small scaling
                    fraction = 12 / 30
                end
                if quotient == string.format("%.4f", 1.6187050359712) then -- medium scaling
                    fraction = 12 / 31
                end
                if quotient == string.format("%.4f", 1.625) then -- large scaling
                    fraction = 12 / 30
                end
                if quotient == string.format("%.4f", 1.6304347826087) then -- extra large scaling
                    fraction = 12 / 29
                end
                if fraction == nil then
                    HSMakeAlert(programName, [[
                        If you're seeing this, it means that Midas didn't properly think about the way VST plugins deal with scaling at your current display resolution.

                        Perhaps you have the plugin (or your OS) set to a custom scaling amount?

                        It is recommended to disable the VST specific shortcuts in the settings.ini if you want to continue to use custom scaling.

                        These shortcuts will be disabled until LES is reloaded.
                    ]], true, "warning")
                    scaling = 1
                    goto yeet
                end

                postpoint["x"] = windowframe.x + (windowframe.w * fraction)
                postpoint["y"] = windowframe.y + titlebarheight() + 20
                hs.eventtap.leftClick(postpoint, 0)
                hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], postpoint):post()

                hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
                fraction = nil
            end
        end

        if keycode == hs.keycodes.map["Z"] and hs.eventtap.checkKeyboardModifiers().cmd and
            hs.eventtap.checkKeyboardModifiers().shift and eventtype == hs.eventtap.event.types.keyDown then -- pro-q 3 redo
            local windowname = hs.window.focusedWindow():title()
            if string.lower(string.gsub(windowname, "(.*)/.*$", "%1")) == "fabfilter pro-q 3" and scaling == 0 then
                local windowframe = hs.window.focusedWindow():frame()
                local prepoint = hs.mouse.absolutePosition()
                local postpoint = {}
                local quotient = windowframe.w / windowframe.h
                quotient = string.format("%.4f", quotient)

                local fraction = nil
                if quotient == string.format("%.4f", 2.0512820512821) then -- mini scaling
                    fraction = 14 / 30
                end
                if quotient == string.format("%.4f", 1.6112266112266) then -- small scaling
                    fraction = 13 / 30
                end
                if quotient == string.format("%.4f", 1.6187050359712) then -- medium scaling
                    fraction = 13 / 31
                end
                if quotient == string.format("%.4f", 1.625) then -- large scaling
                    fraction = 12 / 28
                end
                if quotient == string.format("%.4f", 1.6304347826087) then -- extra large scaling
                    fraction = 13 / 30
                end
                if fraction == nil then
                    HSMakeAlert(programName, [[
                        If you're seeing this, it means that Midas didn't properly think about the way VST plugins deal with scaling at your current display resolution.

                        Perhaps you have the plugin (or your OS) set to a custom scaling amount?

                        It is recommended to disable the VST specific shortcuts in the settings.ini if you want to continue to use custom scaling.

                        These shortcuts will be disabled until LES is reloaded.
                    ]], true, "warning")
                    scaling = 1
                    goto yeet
                end

                postpoint["x"] = windowframe.x + (windowframe.w * fraction)
                postpoint["y"] = windowframe.y + titlebarheight() + 20
                hs.eventtap.leftClick(postpoint, 0)
                hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], postpoint):post()

                hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
                fraction = nil
            end
        end
        ::yeet::
    end

end):start() -- starts the eventtap listener containing all of the keyboard shortcuts.

_G.pausebutton = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(event)
    local keycode = event:getKeyCode()
    local eventtype = event:getType()

    if keycode == hs.keycodes.map["1"] and hs.eventtap.checkKeyboardModifiers().cmd and
        hs.eventtap.checkKeyboardModifiers().shift and eventtype == hs.eventtap.event.types.keyDown then
        if threadsenabled == true then
            hs.alert.show("LES paused")
            disablemacros()
            appwatcher:stop()
        else
            hs.alert.show("LES unpaused")
            enablemacros()
            appwatcher:start()
        end
    end
end):start()
