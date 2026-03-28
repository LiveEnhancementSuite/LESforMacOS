--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

----------------------------------
--  VST shortcuts as hs.hotkey  --
----------------------------------

-- hs.hotkey shortcuts replace the user's original input; so I use a combination of hs.application.watcher and hs.timer to enable them only when nescesary.

if vstshortcuts == 1 then
    undo = hs.hotkey.bind({"cmd"}, "z", function() -- kick 2 undo
        local windowname = hs.window.focusedWindow():title()
        if string.lower(string.gsub(windowname, "(.*)/.*$", "%1")) == "kick 2" then
            local windowframe = hs.window.focusedWindow():frame()
            local prepoint = hs.mouse.absolutePosition()
            local postpoint = {}
            postpoint["x"] = windowframe.x + (windowframe.w / 3.40)
            postpoint["y"] = windowframe.y + titlebarheight() + 85

            hs.eventtap.middleClick(postpoint, 12000) -- for some reason middle click works but not left click
            hs.timer.usleep(12000)
            hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
        end
    end)

    redo = hs.hotkey.bind({"cmd", "shift"}, "z", function() -- kick 2 redo
        local windowname = hs.window.focusedWindow():title()
        if string.lower(string.gsub(windowname, "(.*)/.*$", "%1")) == "kick 2" then
            local windowframe = hs.window.focusedWindow():frame()
            local prepoint = hs.mouse.absolutePosition()
            local postpoint = {}
            postpoint["x"] = windowframe.x + (windowframe.w / 3.19)
            postpoint["y"] = windowframe.y + titlebarheight() + 85

            hs.eventtap.middleClick(postpoint, 12000) -- for some reason middle click works but not left click
            hs.timer.usleep(12000)
            hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], prepoint):post()
        end
    end)
end
