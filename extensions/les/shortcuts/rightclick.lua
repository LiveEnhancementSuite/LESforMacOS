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
    if pluginMenu then
        pluginMenu:popupMenu(hs.mouse.absolutePosition())
    end
end

function spawnPianoMenu() -- spawns and moves the invisible menu bar menu to the mouse location.
    if pianoMenu then
        pianoMenu:popupMenu(hs.mouse.absolutePosition())
    end
end

function getABSTime()
    return hs.timer.absoluteTime()
end

--- Convert nanoseconds to seconds.
--- NOTE: Currently unused. Retained for potential external callers.
---@param nanoseconds number
---@return number
function nanoToSec(nanoseconds)
    return nanoseconds / 1000000000
end

-- The macOS system menu right click behavior is to open the
-- menu on the mouseDown event. If we trigger our action on
-- that event as well the system menu will delay being opened
-- and essentially store the action until our menu closes. We
-- must trigger our event on the mouse up event. -- Direct

-- timeRMBTime: nil = no pending first click; otherwise epoch seconds of last first rightMouseUp
timeRMBTime, firstDown, secondDown = nil, false, true

-- Double-right is slower than double-left for many users; never go below system interval
local timeFrame = math.max(hs.eventtap.doubleClickInterval(), 0.85)

local clickStateProp = hs.eventtap.event.properties.mouseEventClickState

firstRightClick = hs.eventtap.new({hs.eventtap.event.types.rightMouseDown, hs.eventtap.event.types.rightMouseUp},
    function(event)
        if timeRMBTime ~= nil and (hs.timer.secondsSinceEpoch() - timeRMBTime) > timeFrame then
            timeRMBTime, firstDown, secondDown = nil, false, true
        end
        if event:getType() == hs.eventtap.event.types.rightMouseUp then
            -- Prefer system click count (double / triple right-click) when available — more reliable than timing alone.
            local clickState = event:getProperty(clickStateProp)
            if type(clickState) == "number" and clickState >= 2 then
                timeRMBTime, firstDown, secondDown = nil, false, true
                if _G.dynamicreload == 1 then
                    quickreload()
                end
                if _G.pressingshit == true then
                    spawnPianoMenu()
                else
                    spawnPluginMenu()
                end
                return true
            end
            if firstDown and secondDown then
                if _G.dynamicreload == 1 then
                    quickreload()
                end
                if _G.pressingshit == true then -- if you're holding shift, open the piano menu instead.
                    spawnPianoMenu()
                    timeRMBTime, firstDown, secondDown = nil, false, true
                    return true
                else
                    spawnPluginMenu()
                    timeRMBTime, firstDown, secondDown = nil, false, true
                    return true
                end
            elseif not firstDown then
                firstDown = true
                timeRMBTime = hs.timer.secondsSinceEpoch()
                return false
            elseif firstDown then
                secondDown = true
                return false
            else
                timeRMBTime, firstDown, secondDown = nil, false, true
                return false
            end
        end

        return false
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
    local delay = _G.loadspeed <= 0.5 and 0.1 or 0.3
    hs.timer.doAfter(delay, function()
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], bookmark):setProperty(hs.eventtap.event
                                                                                                          .properties
                                                                                                          .mouseEventClickState,
            1):post()
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):post()
    end)
end

local debounce2 = 0
local pluginStats = require("tracking.pluginstats")
-- the plugin names need to have any newline characters removed
function loadPlugin(plugin)
    local pluginCleaned = plugin:match '^%s*(.*%S)' or ''
    -- Record usage statistics
    pluginStats.recordUse(pluginCleaned)
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
        -- Non-blocking: wait for browser to find plugin, then select + add
        hs.timer.doAfter(_G.loadspeed, function()
            hs.eventtap.keyStroke({}, "down", 0)
            hs.eventtap.keyStroke({}, "return", 0)
            hs.eventtap.keyStroke({}, "escape", 0)

            if _G.resettobrowserbookmark == 1 then
                local bookmarkDelay = _G.loadspeed <= 0.5 and 0.1 or 0.3
                hs.timer.doAfter(bookmarkDelay, function()
                    bookmarkfunc()
                end)
            end
        end)
    elseif _G.resettobrowserbookmark == 1 then
        local bookmarkDelay = _G.loadspeed <= 0.5 and 0.1 or 0.3
        hs.timer.doAfter(bookmarkDelay, function()
            bookmarkfunc()
        end)
    end
end
