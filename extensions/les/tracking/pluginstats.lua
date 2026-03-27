--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-----------------------------------------
--  Plugin Usage Statistics Tracker    --
--  Tracks add date, last use, count   --
--  Stored as JSON in ~/.les/resources --
-----------------------------------------

local pluginStats = {}

local STATS_FILE = "plugin_stats.json"

--- Get the full path to the stats file.
---@return string
local function statsFilePath()
    return strJoinPaths(ScriptUserResourcesPath, STATS_FILE)
end

--- Load stats from disk. Returns a table keyed by plugin name.
---@return table<string, {added_at: number, last_used_at: number, use_count: number}>
function pluginStats.load()
    local path = statsFilePath()
    local f = io.open(path, "r")
    if not f then return {} end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return {} end
    local ok, data = pcall(hs.json.decode, raw)
    if ok and type(data) == "table" then
        return data
    end
    return {}
end

--- Save stats table to disk.
---@param data table
function pluginStats.save(data)
    ShellCreateDirectory(ScriptUserResourcesPath)
    local path = statsFilePath()
    local json = hs.json.encode(data, true)
    local f = io.open(path, "w")
    if f then
        f:write(json)
        f:close()
    end
end

--- Record a plugin use event.
--- Creates entry if first time, updates last_used_at and increments use_count.
---@param pluginName string  The display name of the plugin
function pluginStats.recordUse(pluginName)
    if not pluginName or pluginName == "" then return end
    local data = pluginStats.load()
    local now = math.floor(hs.timer.secondsSinceEpoch())
    local entry = data[pluginName]
    if entry then
        entry.last_used_at = now
        entry.use_count = (entry.use_count or 0) + 1
    else
        data[pluginName] = {
            added_at     = now,
            last_used_at = now,
            use_count    = 1,
        }
    end
    pluginStats.save(data)
end

--- Get stats for a single plugin. Returns nil if not tracked.
---@param pluginName string
---@return table|nil
function pluginStats.get(pluginName)
    local data = pluginStats.load()
    return data[pluginName]
end

--- Get all stats.
---@return table
function pluginStats.getAll()
    return pluginStats.load()
end

--- Toggle favorite status for a plugin.
--- Creates an entry if none exists. Returns new favorite state.
---@param pluginName string
---@return boolean
function pluginStats.toggleFavorite(pluginName)
    if not pluginName or pluginName == "" then return false end
    local data = pluginStats.load()
    local now = math.floor(hs.timer.secondsSinceEpoch())
    local entry = data[pluginName]
    if entry then
        entry.favorited = not entry.favorited
    else
        data[pluginName] = {
            added_at     = now,
            last_used_at = 0,
            use_count    = 0,
            favorited    = true,
        }
    end
    pluginStats.save(data)
    return data[pluginName].favorited
end

--- Check if a plugin is favorited.
---@param pluginName string
---@return boolean
function pluginStats.isFavorite(pluginName)
    local data = pluginStats.load()
    local entry = data[pluginName]
    return entry ~= nil and entry.favorited == true
end

--- Get all favorited plugin names, sorted alphabetically.
---@return table
function pluginStats.getFavorites()
    local data = pluginStats.load()
    local favs = {}
    for name, entry in pairs(data) do
        if entry.favorited == true then
            favs[#favs + 1] = name
        end
    end
    table.sort(favs)
    return favs
end

return pluginStats
