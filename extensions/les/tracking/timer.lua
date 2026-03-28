--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

------------------------------
--  Timers and time tracking --
------------------------------

local notifs = require("tracking.notifications")

function setstricttime() -- this function manages the check box in the menu
    local appname = getLiveHsAppObj() -- getting new track title
    if _G.stricttimevar == true then
        _G.stricttimevar = false
        ShellDeleteFile(strJoinPaths(ScriptUserResourcesPath, StrictTimeModifier))
        if appname then
            clock:start()
        end
    else
        _G.stricttimevar = true
        ShellOverwriteFile("beta 9", strJoinPaths(ScriptUserResourcesPath, StrictTimeModifier))
        if isLiveFocused() ~= true then
            clock:stop()
        end
    end
    buildMenuBar()
end

function coolfunc(hswindow, appname, straw) -- function that handles saving and loading of project times in ~/.les/resources/time/

    if trackname ~= nil then -- saving old time
        local oldtrackname = trackname
        print(_G["timer_" .. oldtrackname])
        ShellCreateDirectory(strJoinPaths(ScriptUserResourcesPath, "time"))
        local filepath = GetDataPath([[resources/time/]] .. oldtrackname .. "_time" .. [[.txt]])
        local f2 = io.open(filepath, "r")
        if f2 ~= nil then
            io.close(f2)
            ShellDeleteFile(strJoinPaths(strJoinPaths(ScriptUserResourcesPath, "time"), oldtrackname .. "_time" .. [[.txt]]))
        end
        ShellOverwriteFile(_G["timer_" .. oldtrackname], strJoinPaths(strJoinPaths(ScriptUserResourcesPath, "time"), oldtrackname .. "_time" .. [[.txt]]))
        _G["timer_" .. oldtrackname] = nil
    end

    local appname = getLiveHsAppObj() -- getting new track title
    if appname and appname:mainWindow() then
        local mainwindowname = appname:mainWindow():title()
        -- Export / render detection: notify before updating trackname
        notifs.checkExport(mainwindowname)
        if string.find(mainwindowname, "%[") ~= nil and string.find(mainwindowname, "%]") ~= nil then
            trackname = (mainwindowname:gsub(".*(.*)%[", ""))
            trackname = (trackname:gsub("%].*(.*)", ""))
            trackname = trackname:gsub("[%p%c%s]", "_")
            print("trackname = " .. trackname)
        else
            trackname = "unsaved_project"
        end
        -- Reset hourly counter for the newly active project
        notifs.onProjectChange(trackname)
    else
        trackname = nil
        notifs.onProjectChange(nil)
        return
    end

    local filepath = GetDataPath([[resources/time/]] .. trackname .. "_time" .. [[.txt]]) -- loading old time (if it exists)
    local f = io.open(filepath, "r")
    if f ~= nil then
        print("timer file found")
        for line in f:lines() do
            print("old timer found for this project: " .. line)
            _G["timer_" .. trackname] = line
        end
        f:close()
        return true
    else
        return
    end
end
windowfilter = hs.window.filter.new({'Live'}, nil) -- activating the window filter
windowfilter:subscribe(hs.window.filter.windowTitleChanged, coolfunc) -- if the title of the active window changes, execute this function again.

-- Cache for timer keys to avoid repeated string concatenation every second
local timerKeyCache = {}

local function getTimerKey(name)
    local cached = timerKeyCache[name]
    if cached then return cached end
    cached = "timer_" .. name
    timerKeyCache[name] = cached
    return cached
end

-- Cache for VST window detection
local vstWindowState = { enabled = false, lastTitle = nil }

local function extractVstName(title)
    return title:match("^([^/]+)") or title
end

function timerfunc()
    -- VST window detection (runs every second)
    if vstshortcuts == 1 then
        local focusedWin = hs.window.focusedWindow()
        if focusedWin == nil then return end

        local title = focusedWin:title()
        -- Only re-check if window title changed
        if title ~= vstWindowState.lastTitle then
            vstWindowState.lastTitle = title
            local vstName = extractVstName(title):lower()
            if vstName == "kick 2" then
                if not vstWindowState.enabled then
                    print("vst window found")
                    vstWindowState.enabled = true
                    undo:enable()
                    redo:enable()
                end
            elseif vstWindowState.enabled then
                print("vst shortcuts disabled in-daw")
                vstWindowState.enabled = false
                undo:disable()
                redo:disable()
            end
        end
    end

    -- Track time counting
    if trackname == nil then
        coolfunc()
    end
    if trackname ~= nil then
        local timerKey = getTimerKey(trackname)
        _G[timerKey] = (_G[timerKey] or 0) + 1
    end

    -- Hourly session time notification
    notifs.checkHourly()
end
clock = hs.timer.new(1, timerfunc)

function requesttime() -- this is the function for when someone checks the current project time. Formatting the seconds into hours/minutes/seconds and presenting it in a nice dialog box.
    local currenttime = nil
    local response = nil

    if trackname == nil then
        response = hs.dialog.blockAlert(L("timer_no_project_title"), L("timer_no_project_detail"), L("btn_ok"))
        return
    end

    if _G["timer_" .. trackname] <= 0 or _G["timer_" .. trackname] == nil then
        currenttime = L("timer_zero")
    else
        local totalSeconds = _G["timer_" .. trackname]
        local hours = math.floor(totalSeconds / 3600)
        local mins = math.floor((totalSeconds % 3600) / 60)
        local secs = math.floor(totalSeconds % 60)
        currenttime = string.format(L("timer_format"), hours, mins, secs)
    end

    print(currenttime)

    if trackname == "unsaved_project" then
        response = hs.dialog.blockAlert(L("timer_unsaved_project"), currenttime, L("btn_ok"), L("btn_reset_time"),
            "NSCriticalAlertStyle")
    else
        response = hs.dialog.blockAlert(string.format(L("timer_project"), trackname), currenttime, L("btn_ok"),
            L("btn_reset_time"), "NSCriticalAlertStyle")
    end

    if response == L("btn_reset_time") then
        response = hs.dialog.blockAlert(L("timer_reset_title"), L("timer_reset_detail"), L("btn_no"), L("btn_yes"),
            "NSCriticalAlertStyle")
        if response == L("btn_yes") then
            ShellDeleteFile(strJoinPaths(strJoinPaths(ScriptUserResourcesPath, "time"), trackname .. "_time" .. [[.txt]]))
            coolfunc()
        end
    end

    -- Focus Live again when closing the dialog box
    local hsAppObj = getLiveHsAppObj()
    if hsAppObj ~= nil then
      hsAppObj:activate()
    end
end
