--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

------------------------------
--  App lifecycle management --
------------------------------

function disablemacros() -- this function stops all of the eventtap events, causing the shortcuts to be disabled.
    threadsenabled = false
    if dingodango then
        dingodango:stop()
    end
    directshyper:disable()
    buplicate:disable()
    _G.quickmacro:stop()
    firstRightClick:stop()

    if vstshortcuts == 1 then
        vstshenabled = 0
        undo:disable()
        redo:disable()
    end

    if keyhandlerevent then
        keyhandlerevent:stop()
    end
    modifierHandler:stop()

    -- Update menubar icon to reflect inactive state
    if updateMenuBarState then updateMenuBarState("inactive") end
end

function enablemacros() -- this function enables all of the eventtap events, causing the shortcuts to be enabled.
    threadsenabled = true
    if _G.enabledebug == 1 then
        dingodango:start()
    end
    directshyper:enable()
    buplicate:enable()
    _G.quickmacro:start()
    firstRightClick:start()

    if _G.nomacro == false then
        modifierHandler:start()
    end

    -- Currently setting it as a global because it holds up the main
    -- thread for a bit and we don't want to recalculate.
    --
    -- This table may be invalid if the user switches between Live versions,
    -- however unlikely that may be.
    _G.gValidTitleTable = getValidTitles()

    -- Update menubar icon and show HUD to reflect active state
    if updateMenuBarState then updateMenuBarState("active") end
    if showStatusHUD      then showStatusHUD("active") end
end

disablemacros() -- macros are turned off by default because live is never focused at this point in time, hammerspoon is.
-- if it was, the watcher would turn it on again anyway

threadsenabled = false
appwatcher = hs.application.watcher.new(function(name, event, app)
    appwatch(name, event, app)
end):start() -- terminates hotkeys when ableton is unfocussed

-- If Ableton was already frontmost when LES finished loading, no activated event
-- runs until the user switches apps; without this, event taps stay stopped.
if isLiveFocused() and threadsenabled == false then
    print("live was already front at LES init — enabling macros")
    enablemacros()
    clock:start()
    _G.pausebutton:start()
end

function appwatch(name, event, app)
    -- If something other than Live got caught by the application watcher, just
    -- silently pretend it doesn't exist and hope the next event nets us a Live
    -- instance
    if isHsAppObjLive(app) == false then
        return
    end

    if event == hs.application.watcher.terminated then
        if clock:running() == true then
            clock:stop()
        end
        coolfunc()
        print("Live was quit")
        return
    end

    -- Only invalidate cache when the Live app itself is involved
    invalidateLiveAppCache()

    if event == hs.application.watcher.activated or event == hs.application.watcher.deactivated then
        -- Do not compare hs.application userdata with == (can be false for the same running app).
        local focusedWin = hs.window.focusedWindow()
        local frontApp = focusedWin and focusedWin:application()
        local liveFocused = frontApp ~= nil and isHsAppObjLive(frontApp)

        if liveFocused then
            if threadsenabled == false then
                print("live is in window focus")
                enablemacros()
                clock:start()
                _G.pausebutton:start()
            end
        elseif threadsenabled == true then
            print("live is not in window focus")
            disablemacros()
            if _G.stricttimevar == true then
                clock:stop()
                _G.pausebutton:stop()
            else
                print("clock wasn't stopped because strict time is off")
            end
        end

        -- Focus can lag slightly behind Live activation; one delayed sync avoids taps staying off.
        if event == hs.application.watcher.activated and not liveFocused then
            hs.timer.doAfter(0.12, function()
                if isLiveFocused() and threadsenabled == false then
                    print("live focus delayed sync — enabling macros")
                    enablemacros()
                    clock:start()
                    _G.pausebutton:start()
                end
            end)
        end
    end
end

hs.dockIcon(false) -- removes the hammerspoon icon from the dock
if console then
    console:close()
end -- attempting to close the console one more time, just in case.
