--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

--------------------------
--  Piano roll macros   --
--------------------------

-- this is a seperate eventtap event for the piano roll macro and contains all of the piano roll macro functionality.

_G.buttonstatevar = false
local keyHandler = function(e)
    local buttonstate = e:getButtonState(0)
    local buttonstate2 = e:getButtonState(1)
    local clickState = hs.eventtap.event.properties.mouseEventClickState
    if buttonstate == true and _G.buttonstatevar == false then
        _G.buttonstatevar = true
        local point = hs.mouse.absolutePosition()
        point["__luaSkinType"] = nil
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1)
            :post()
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):post()
        hs.timer.usleep(6000)
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 2)
            :post()
    elseif buttonstate == false and _G.buttonstatevar == true then
        _G.buttonstatevar = false
        local point = hs.mouse.absolutePosition()
        point["__luaSkinType"] = nil
        hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 2):post()
        if _G.pressingshit == true then
            _G.shitvar = 1
        end
        if _G.shitvar == 1 and _G.pressingshit == false then
            _G.shitvar = 0
            _G.stampselect = nil
            return
        end
        if _G.stampselect ~= nil then
            _G.stampselect()
            if pressingshit == false then
                _G.stampselect = nil
                _G.shitvar = 0
            end
        end
    end
end

-- this is the hammerspoon equivalent of autohotkey's "getKeyState"
_G.keyhandlervar = false
_G.pressingshit = false
modifierHandler = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp,
                                         hs.eventtap.event.types.flagsChanged}, function(e)

    local keycode = e:getKeyCode()
    local eventtype = e:getType()
    if keycode == _G.pianorollmacro and eventtype == hs.eventtap.event.types.keyDown and _G.keyhandlervar == false then -- if the keyhandler is on, the event function above will start
        print("keyhandler on")
        _G.keyhandlervar = true
        keyhandlerevent = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.leftMouseUp,
                                           hs.eventtap.event.types.rightMouseDown}, keyHandler):start()
    elseif keycode == _G.pianorollmacro and eventtype == hs.eventtap.event.types.keyUp and _G.keyhandlervar == true then
        print("keyhandler off")
        _G.keyhandlervar = false
        keyhandlerevent:stop()
        keyhandlerevent = nil
    end

    local flags = e:getFlags()
    local onlyShiftPressed = false
    for k, v in pairs(flags) do
        onlyShiftPressed = v and k == "shift"
        if not onlyShiftPressed then
            break
        end
    end

    if onlyShiftPressed and _G.pressingshit == false then
        _G.pressingshit = true
    elseif not next(flags) and _G.pressingshit == true then
        _G.pressingshit = false
    end

    return false
end)

if _G.nomacro == false then
    modifierHandler:start()
end
