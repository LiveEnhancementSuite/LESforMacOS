--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-----------------------------
--  Right Clicking & Menus --
-----------------------------

function spawnPluginMenu() -- spawns and moves the invisible menu bar menu to the mouse location.
    pluginMenu:popupMenu(hs.mouse.absolutePosition())
end

function spawnPianoMenu() -- spawns and moves the invisible menu bar menu to the mouse location.
    pianoMenu:popupMenu(hs.mouse.absolutePosition())
end

function getABSTime()
    return hs.timer.absoluteTime()
end

function nanoToSec(nanoseconds)
    local seconds = nanoseconds * 1000000000
    return seconds
end

-- The macOS system menu right click behavior is to open the
-- menu on the mouseDown event. If we trigger our action on
-- that event as well the system menu will delay being opened
-- and essentially store the action until our menu closes. We
-- must trigger our event on the mouse up event. -- Direct

timeRMBTime, firstDown, secondDown = 0, false, true

local timeFrame = hs.eventtap.doubleClickInterval()

firstRightClick = hs.eventtap.new({hs.eventtap.event.types.rightMouseDown, hs.eventtap.event.types.rightMouseUp},
    function(event)

        if timeRMBTime == nil then
            timeRMBTime, firstDown, secondDown = 0, false, true
        end

        if (hs.timer.secondsSinceEpoch() - timeRMBTime) > timeFrame then
            timeRMBTime, firstDown, secondDown = 0, false, true
        end
        if event:getType() == hs.eventtap.event.types.rightMouseUp then
            if firstDown and secondDown then
                if _G.dynamicreload == 1 then
                    quickreload()
                end
                if _G.pressingshit == true then -- if you're holding shift, open the piano menu instead.
                    spawnPianoMenu()
                    timeRMBTime, firstDown, secondDown = 0, false, true
                else
                    spawnPluginMenu()
                    timeRMBTime, firstDown, secondDown = 0, false, true
                    return
                end
            elseif not firstDown then
                firstDown = true
                timeRMBTime = hs.timer.secondsSinceEpoch()
                return
            elseif firstDown then
                secondDown = true
                return
            else
                timeRMBTime, firstDown, secondDown = 0, false, true
                return
            end
        end

        return
    end):start() -- starts the eventtap listener for double right clicks.

function titlebarheight()
    local zoombuttonrect = hs.window.focusedWindow():zoomButtonRect()
    return zoombuttonrect.h + 4
end

function bookmarkfunc() -- this allows you to use the bookmark click stuff.
    local point = {}
    local dimensions = getLiveHsAppObj():mainWindow():frame()
    local bookmark = {}
    bookmark["x"] = _G.bookmarkx + dimensions.x
    bookmark["y"] = _G.bookmarky + dimensions.y + titlebarheight()
    point = hs.mouse.absolutePosition()
    point["__luaSkinType"] = nil
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], bookmark):setProperty(hs.eventtap.event
                                                                                                        .properties
                                                                                                        .mouseEventClickState,
        1):post()
    local sleep2
    if _G.loadspeed <= 0.5 then
        sleep2 = astSleep(0.1)
    else
        sleep2 = astSleep(0.3)
    end
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], bookmark):setProperty(hs.eventtap.event
                                                                                                      .properties
                                                                                                      .mouseEventClickState,
        1):post()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):post()
end

local debounce2 = 0
-- the plugin names nead to have any newline characters removed
function loadPlugin(plugin)
    local pluginCleaned = plugin:match '^%s*(.*%S)' or ''
    hs.eventtap.keyStroke("cmd", "f", 0)
    hs.eventtap.keyStrokes(pluginCleaned)
    local tempautoadd = nil

    if hs.eventtap.checkKeyboardModifiers().cmd then -- if you're holding cmd, invert the option for autoadd set in the settings.ini file temporarily.
        if _G.autoadd == 1 then
            tempautoadd = 0
        elseif _G.autoadd == 0 then
            tempautoadd = 1
        end
    else
        tempautoadd = _G.autoadd
    end

    print("tempautoadd = " .. tempautoadd .. " and _G.autoadd = " .. _G.autoadd)

    if tempautoadd == 1 then
        local sleep = astSleep(_G.loadspeed)
        if sleep == false then
            hs.alert.show("applescript sleep failed to execute properly")
        end
        hs.eventtap.keyStroke({}, "down", 0)
        hs.eventtap.keyStroke({}, "return", 0)
        hs.eventtap.keyStroke({}, "escape", 0)
    end

    if _G.resettobrowserbookmark == 1 then
        local sleep2
        if _G.loadspeed <= 0.5 then
            sleep2 = astSleep(0.1)
        else
            sleep2 = astSleep(0.3)
        end

        if sleep2 ~= nil then
            bookmarkfunc()
        end
    end
    return
end
