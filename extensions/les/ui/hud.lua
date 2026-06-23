--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-------------------------------------------------
--  Status HUD (hs.canvas)                     --
--  Floating pill-shaped overlay showing       --
--  LES active / paused / inactive state       --
-------------------------------------------------

---@type hs.canvas|nil
local _hudCanvas = nil
---@type hs.timer|nil
local _hudTimer  = nil

-- State definitions: icon (emoji), label text, background color, text color
local HUD_DEFS = {
    active   = {
        icon = "●",
        label = "LES アクティブ",
        bg   = {red = 0.188, green = 0.820, blue = 0.345, alpha = 0.92},
        fg   = {red = 1.0,   green = 1.0,   blue = 1.0,   alpha = 1.0},
    },
    paused   = {
        icon = "⏸",
        label = "LES 一時停止",
        bg   = {red = 1.0,   green = 0.624, blue = 0.000, alpha = 0.92},
        fg   = {red = 0.0,   green = 0.0,   blue = 0.0,   alpha = 1.0},
    },
    inactive = {
        icon = "○",
        label = "LES 非アクティブ",
        bg   = {red = 0.172, green = 0.172, blue = 0.180, alpha = 0.90},
        fg   = {red = 0.700, green = 0.700, blue = 0.700, alpha = 1.0},
    },
}

local HUD_W       = 210  -- pill width  (px)
local HUD_H       = 42   -- pill height (px)
local HUD_PADDING = 16   -- distance from screen edge
local HUD_TTL     = 2.0  -- seconds before auto-hide

local function destroyHUD()
    if _hudTimer  ~= nil then _hudTimer:stop();  _hudTimer  = nil end
    if _hudCanvas ~= nil then _hudCanvas:delete(); _hudCanvas = nil end
end

--- Show a floating pill-shaped HUD indicating the current LES state.
---@param state "active"|"paused"|"inactive"
---@param ttl number|nil  Seconds before auto-hide (default HUD_TTL). Pass 0 to keep visible.
function showStatusHUD(state, ttl)
    local def = HUD_DEFS[state]
    if def == nil then return end

    -- Allow time-to-live override
    local duration = (ttl ~= nil) and ttl or HUD_TTL

    -- Position: top-right corner, just below the menu bar (~28 px)
    local sf = hs.screen.mainScreen():frame()
    local x  = sf.x + sf.w - HUD_W - HUD_PADDING
    local y  = sf.y + 28

    destroyHUD()

    _hudCanvas = hs.canvas.new({x = x, y = y, w = HUD_W, h = HUD_H})

    -- Background rounded pill
    _hudCanvas[1] = {
        type             = "rectangle",
        action           = "fill",
        fillColor        = def.bg,
        roundedRectRadii = {xRadius = HUD_H / 2, yRadius = HUD_H / 2},
        frame            = {x = 0, y = 0, w = HUD_W, h = HUD_H},
    }

    -- State icon (left side)
    _hudCanvas[2] = {
        type          = "text",
        text          = def.icon,
        textSize      = 16,
        textColor     = def.fg,
        textAlignment = "center",
        frame         = {x = 8, y = 11, w = 26, h = 22},
    }

    -- Label text
    _hudCanvas[3] = {
        type          = "text",
        text          = def.label,
        textFont      = "-apple-system",
        textSize      = 13,
        textColor     = def.fg,
        textAlignment = "left",
        frame         = {x = 38, y = 13, w = HUD_W - 48, h = 20},
    }

    _hudCanvas:show()

    if duration > 0 then
        _hudTimer = hs.timer.doAfter(duration, destroyHUD)
    end
end

--- Immediately hide the HUD (e.g. when transitioning to another state).
function hideStatusHUD()
    destroyHUD()
end

-------------------------------------------------
--  Menubar icon state updates               --
--  Requires LESmenubar to be initialised.   --
-------------------------------------------------

local MENUBAR_STATES = {
    active   = nil,   -- nil = use normal icon/texticon setting
    paused   = "⏸ LES",
    inactive = nil,   -- nil = use normal icon/texticon setting
}

--- Update the menubar icon/title to reflect the current LES state.
---@param state "active"|"paused"|"inactive"
function updateMenuBarState(state)
    if LESmenubar == nil then return end

    local override = MENUBAR_STATES[state]
    if override ~= nil then
        -- Forced text override (e.g. pause indicator) — icon would crowd the label
        LESmenubar:setIcon(nil)
        LESmenubar:setTitle(override)
    else
        -- Restore normal icon or text (shared with menus.plugin)
        applyLesMainMenubarAppearance(LESmenubar)
    end
end
