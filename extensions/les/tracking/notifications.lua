--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-------------------------------------------------
--  macOS Notification Integration             --
--  - エクスポート完了通知                        --
--  - 1時間ごとのプロジェクト時間通知              --
--  設定: notifyexport / notifyhourly           --
-------------------------------------------------

local notifications = {}

-- ── State ────────────────────────────────────────────────────────────

--- True while Ableton is rendering/exporting
local _wasRendering = false

--- Last hour count for which a notification was sent (per project session)
local _lastNotifiedHour = 0

-- ── Helpers ──────────────────────────────────────────────────────────

--- Send a macOS notification via hs.notify.
---@param title string
---@param message string
---@param soundName string|nil  hs.notify sound name (e.g. "Glass", "Ping")
local function send(title, message, soundName)
    local n = hs.notify.new({
        title           = title,
        informativeText = message,
        withdrawAfter   = 8,
    })
    if soundName then
        n:soundName(soundName)
    end
    n:send()
end

--- Friendly project display name (underscores → spaces, skip "unsaved").
---@param name string|nil
---@return string
local function displayName(name)
    if not name or name == "unsaved_project" then return "プロジェクト" end
    return name:gsub("_", " ")
end

-- ── Export / Render detection ─────────────────────────────────────────

--- Call this whenever the Live window title changes.
--- Detects transitions from rendering → not rendering and fires a notification.
---@param title string  Current Live main window title
function notifications.checkExport(title)
    if _G.notifyexport ~= 1 then
        _wasRendering = false
        return
    end

    -- Live shows "Rendering: XX%" or "Rendering..." in the title bar during export
    local isRendering = title:lower():find("rendering") ~= nil

    if _wasRendering and not isRendering then
        send(
            "エクスポート完了 ✓",
            displayName(_G.trackname) .. " のレンダリングが完了しました",
            "Glass"
        )
    end

    _wasRendering = isRendering
end

-- ── Hourly project time notification ─────────────────────────────────

--- Call this every second from timerfunc().
--- Fires a notification when elapsed project time crosses an hour boundary.
function notifications.checkHourly()
    if _G.notifyhourly ~= 1 then return end
    if not _G.trackname then return end

    local elapsed = tonumber(_G["timer_" .. _G.trackname]) or 0
    local hours = math.floor(elapsed / 3600)

    if hours > 0 and hours ~= _lastNotifiedHour then
        _lastNotifiedHour = hours
        send(
            string.format("%d 時間経過 ⏱", hours),
            string.format("「%s」のセッションが %d 時間になりました", displayName(_G.trackname), hours),
            "Ping"
        )
    end
end

--- Call this when the active project changes (from coolfunc).
--- Resets the hourly counter to the new project's already-elapsed hours,
--- so loading a project that already has 2h does not immediately notify.
---@param newTrackname string|nil
function notifications.onProjectChange(newTrackname)
    _wasRendering = false
    if not newTrackname then
        _lastNotifiedHour = 0
        return
    end
    local elapsed = tonumber(_G["timer_" .. newTrackname]) or 0
    _lastNotifiedHour = math.floor(elapsed / 3600)
end

return notifications
