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
        if string.find(mainwindowname, "%[") ~= nil and string.find(mainwindowname, "%]") ~= nil then
            trackname = (mainwindowname:gsub(".*(.*)%[", ""))
            trackname = (trackname:gsub("%].*(.*)", ""))
            trackname = trackname:gsub("[%p%c%s]", "_")
            print("trackname = " .. trackname)
        else
            trackname = "unsaved_project"
        end
    else
        trackname = nil
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

function timerfunc()
    -- function that writes the time and checks for vst windows if nescesary (currently in seconds)
    -- unfortunately I couldn't use the appwatcher for this, because the app watcher doesn't detect window switches within the same application..
    if vstshortcuts == 1 then
        if hs.window.focusedWindow() == nil then
            return
        end
        if string.lower(string.gsub(hs.window.focusedWindow():title(), "(.*)/.*$", "%1")) == "kick 2" then
            if vstshenabled == 0 then
                print("vst window found")
                vstshenabled = 1
                undo:enable()
                redo:enable()
            end
        elseif vstshenabled == 1 then
            print("vst shortcuts disabled in-daw")
            vstshenabled = 0
            undo:disable()
            redo:disable()
        end
    end

    if trackname == nil then
        coolfunc()
    end
    if trackname ~= nil then
        local timerKey = "timer_" .. trackname
        if _G[timerKey] == nil then
            _G[timerKey] = 1
        else
            _G[timerKey] = _G[timerKey] + 1
        end
    end
end
clock = hs.timer.new(1, timerfunc)

function requesttime() -- this is the function for when someone checks the current project time. Formatting the seconds into hours/minutes/seconds and presenting it in a nice dialog box.
    local currenttime = nil
    local response = nil

    if trackname == nil then
        response = hs.dialog.blockAlert("There was no open project detected.",
            "Please open or focus Live for a second and try again.", "Ok")
        return
    end

    if _G["timer_" .. trackname] <= 0 or _G["timer_" .. trackname] == nil then
        currenttime = "0 hours, 0 minutes, and 0 seconds"
    else
        local totalSeconds = _G["timer_" .. trackname]
        local hours = math.floor(totalSeconds / 3600)
        local mins = math.floor((totalSeconds % 3600) / 60)
        local secs = math.floor(totalSeconds % 60)
        currenttime = string.format("%d hours, %d minutes, and %02d seconds", hours, mins, secs)
    end

    print(currenttime)

    if trackname == "unsaved_project" then
        response = hs.dialog.blockAlert("Time spent in unsaved projects:", currenttime, "Ok", "Reset Time",
            "NSCriticalAlertStyle")
    else
        response = hs.dialog.blockAlert("Time spent inside the [" .. trackname .. "] project:", currenttime, "Ok",
            "Reset Time", "NSCriticalAlertStyle")
    end

    if response == "Reset Time" then
        response = hs.dialog.blockAlert("Are you sure?", "This action cannot be undone", "No", "Yes",
            "NSCriticalAlertStyle")
        if response == "Yes" then
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
