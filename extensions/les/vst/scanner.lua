--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

---------------------------------------------------
--  Plugin Scanner                               --
--  Discovers AU/VST3 plugins and auto-          --
--  categorizes them from system metadata        --
--                                               --
--  Supports incremental (diff) scanning:        --
--  caches scan results and only processes new   --
--  or removed plugins on subsequent runs.       --
---------------------------------------------------

local scanner = {}

local CACHE_FILE = "plugin_cache.json"

-- ── Keyword heuristic map ──────────────────────────────────────────────
-- Matched case-insensitively against plugin name. First match wins.
local KEYWORD_CATEGORIES = {
    { category = "Compressor",   keywords = { "compressor", "comp%f[%A]", "limiter", "limit%f[%A]", "gate%f[%A]", "expander", "dynamics", "transient", "multiband", "de%-ess", "deess" } },
    { category = "EQ",           keywords = { "%feq%f[%A]", "equaliz", "filter%f[%A]", "tilt%f[%A]", "channel eq", "parametric", "graphic eq", "linear phase" } },
    { category = "Reverb",       keywords = { "reverb", "verb%f[%A]", "room%f[%A]", "hall%f[%A]", "plate%f[%A]", "spring%f[%A]", "convolution", "space%f[%A]" } },
    { category = "Delay",        keywords = { "delay", "echo%f[%A]", "tape%f[%A]" } },
    { category = "Distortion",   keywords = { "distort", "saturate", "saturat", "overdrive", "drive%f[%A]", "clip%f[%A]", "crush", "bitcrush", "amp%f[%A]", "fuzz", "waveshap", "decimate" } },
    { category = "Modulation",   keywords = { "chorus", "flanger", "phaser", "tremolo", "vibrato", "ensemble", "rotary", "leslie" } },
    { category = "Utility",      keywords = { "utility", "gain%f[%A]", "meter%f[%A]", "analyz", "spectrum", "mono%f[%A]", "stereo%f[%A]", "imager", "tuner", "test%f[%A]", "tone%f[%A]", "loudness" } },
    { category = "Pitch",        keywords = { "pitch", "autotune", "auto%-tune", "tune%f[%A]", "harmoniz", "vocoder", "formant" } },
    { category = "Synthesizer",  keywords = { "synth", "oscillat", "wavetable", "subtractive", "additive", "fm%f[%A]", "granular", "analog%f[%A]" } },
    { category = "Sampler",      keywords = { "sampler", "sample%f[%A]", "drum rack", "drum%f[%A]", "rompler", "kontakt" } },
    { category = "MIDI Effect",  keywords = { "midi", "arpeggiator", "arpeggio", "chord%f[%A]", "scale%f[%A]", "note%f[%A]", "velocity%f[%A]", "random%f[%A]" } },
}

-- ── VST3 subcategory string → LES category mapping ────────────────────
local VST3_SUBCAT_MAP = {
    ["Fx|Dynamics"]    = "Compressor",
    ["Fx|EQ"]          = "EQ",
    ["Fx|Filter"]      = "EQ",
    ["Fx|Reverb"]      = "Reverb",
    ["Fx|Delay"]       = "Delay",
    ["Fx|Distortion"]  = "Distortion",
    ["Fx|Modulation"]  = "Modulation",
    ["Fx|Pitch Shift"] = "Pitch",
    ["Fx|Tools"]       = "Utility",
    ["Fx|Analyzer"]    = "Utility",
    ["Fx|Spatial"]     = "Reverb",
    ["Fx|Mastering"]   = "Mastering",
    ["Fx|Restoration"] = "Utility",
    ["Fx"]             = "Effects",
    ["Instrument"]     = "Instruments",
    ["Instrument|Synth"]  = "Synthesizer",
    ["Instrument|Drum"]   = "Sampler",
    ["Instrument|Sampler"] = "Sampler",
    ["Instrument|Piano"]   = "Instruments",
}

-- ── Preferred category order for menuconfig.ini generation ─────────────
local CATEGORY_ORDER = {
    "Instruments", "Synthesizer", "Sampler", "Generator",
    "Compressor", "EQ", "Reverb", "Delay", "Distortion",
    "Modulation", "Pitch", "Mastering", "Utility",
    "MIDI Effect", "Effects",
}

-- ═══════════════════════════════════════════════════════════════════════
--  Cache: stores scan results to enable incremental diff scanning
-- ═══════════════════════════════════════════════════════════════════════

---@return string
local function cacheFilePath()
    return strJoinPaths(ScriptUserResourcesPath, CACHE_FILE)
end

--- Load cached scan data from disk.
--- Returns { plugins = { [name] = { category, format } }, scanned_at = timestamp }
---@return table
function scanner.loadCache()
    local path = cacheFilePath()
    local f = io.open(path, "r")
    if not f then return { plugins = {}, scanned_at = 0 } end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return { plugins = {}, scanned_at = 0 } end
    local ok, data = pcall(hs.json.decode, raw)
    if ok and type(data) == "table" and type(data.plugins) == "table" then
        return data
    end
    return { plugins = {}, scanned_at = 0 }
end

--- Save scan cache to disk.
---@param data table
function scanner.saveCache(data)
    ShellCreateDirectory(ScriptUserResourcesPath)
    local path = cacheFilePath()
    local json = hs.json.encode(data, true)
    local f = io.open(path, "w")
    if f then
        f:write(json)
        f:close()
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  Classification
-- ═══════════════════════════════════════════════════════════════════════

--- Classify a plugin name using keyword heuristics.
---@param name string
---@return string|nil
function scanner.classifyByKeyword(name)
    local lower = name:lower()
    for _, rule in ipairs(KEYWORD_CATEGORIES) do
        for _, kw in ipairs(rule.keywords) do
            if lower:find(kw) then
                return rule.category
            end
        end
    end
    return nil
end

--- Map a VST3 subcategory string to an LES category.
---@param subcat string
---@return string|nil
function scanner.classifyByVST3Subcat(subcat)
    if not subcat then return nil end
    for key, cat in pairs(VST3_SUBCAT_MAP) do
        if subcat:find(key, 1, true) then
            return cat
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════
--  System scanning (AU + VST3)
-- ═══════════════════════════════════════════════════════════════════════

--- Scan Audio Unit plugins using system_profiler.
---@return table
function scanner.scanAU()
    local results = {}
    local handle = io.popen("/usr/sbin/system_profiler SPAudioDataType 2>/dev/null")
    if not handle then return results end
    local output = handle:read("*a")
    handle:close()

    if not output or output == "" then return results end

    local currentName = nil
    for line in output:gmatch("[^\n]+") do
        local pluginName = line:match("^%s%s%s%s(%S.+):$")
        if pluginName then
            currentName = pluginName
        end
        if currentName then
            local pluginType = line:match("^%s+Type:%s+(.+)$")
            if pluginType then
                local topCat = "Effects"
                local trimmedType = pluginType:match("^%s*(.-)%s*$")
                if trimmedType == "Music Device" or trimmedType == "Music Effect" then
                    topCat = "Instruments"
                elseif trimmedType == "Generator" then
                    topCat = "Generator"
                end
                local subCat = scanner.classifyByKeyword(currentName)
                table.insert(results, {
                    name     = currentName,
                    format   = "AU",
                    category = subCat or topCat,
                })
                currentName = nil
            end
        end
    end
    return results
end

--- Scan VST3 plugins by reading moduleinfo.json from .vst3 bundles.
---@return table
function scanner.scanVST3()
    local results = {}
    local searchPaths = {
        "/Library/Audio/Plug-Ins/VST3",
        (os.getenv("HOME") or "") .. "/Library/Audio/Plug-Ins/VST3",
    }

    for _, dir in ipairs(searchPaths) do
        local handle = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
        if handle then
            for entry in handle:lines() do
                if entry:match("%.vst3$") then
                    local bundlePath = dir .. "/" .. entry
                    local pluginName = entry:gsub("%.vst3$", "")

                    local category = nil
                    local miPath = bundlePath .. "/Contents/moduleinfo.json"
                    local mf = io.open(miPath, "r")
                    if mf then
                        local raw = mf:read("*a")
                        mf:close()
                        local subcat = raw:match('"sub_categories"%s*:%s*"([^"]+)"')
                            or raw:match('"subcategories"%s*:%s*%[%s*"([^"]+)"')
                            or raw:match('"category"%s*:%s*"([^"]+)"')
                        category = scanner.classifyByVST3Subcat(subcat)
                    end

                    if not category then
                        category = scanner.classifyByKeyword(pluginName) or "Effects"
                    end

                    table.insert(results, {
                        name     = pluginName,
                        format   = "VST3",
                        category = category,
                    })
                end
            end
            handle:close()
        end
    end
    return results
end

-- ═══════════════════════════════════════════════════════════════════════
--  Full scan: merge AU + VST3, deduplicate
-- ═══════════════════════════════════════════════════════════════════════

--- Run a full scan, return flat map { [name] = { category, format } }.
---@return table<string, table>
function scanner.fullScan()
    local auPlugins = scanner.scanAU()
    local vst3Plugins = scanner.scanVST3()

    local byName = {}
    for _, p in ipairs(auPlugins) do
        byName[p.name] = { category = p.category, format = p.format }
    end
    for _, p in ipairs(vst3Plugins) do
        local existing = byName[p.name]
        if not existing then
            byName[p.name] = { category = p.category, format = p.format }
        elseif existing.category == "Effects" or existing.category == "Instruments" then
            if p.category ~= "Effects" and p.category ~= "Instruments" then
                existing.category = p.category
                existing.format = existing.format .. "/VST3"
            end
        end
    end
    return byName
end

-- ═══════════════════════════════════════════════════════════════════════
--  Incremental scan: compare with cache, return diff
-- ═══════════════════════════════════════════════════════════════════════

--- Perform incremental scan. Returns added, removed, and full results.
---@return table added   { [name] = { category, format } }
---@return table removed { [name] = { category, format } }
---@return table all     { [name] = { category, format } }
function scanner.incrementalScan()
    local cache = scanner.loadCache()
    local current = scanner.fullScan()

    local added = {}
    local removed = {}

    -- Find newly added plugins
    for name, info in pairs(current) do
        if not cache.plugins[name] then
            added[name] = info
        end
    end

    -- Find removed plugins
    for name, info in pairs(cache.plugins) do
        if not current[name] then
            removed[name] = info
        end
    end

    -- Update cache
    scanner.saveCache({
        plugins    = current,
        scanned_at = math.floor(hs.timer.secondsSinceEpoch()),
    })

    return added, removed, current
end

-- ═══════════════════════════════════════════════════════════════════════
--  menuconfig.ini generation and merging
-- ═══════════════════════════════════════════════════════════════════════

--- Group a flat plugin map by category.
---@param plugins table<string, table>
---@return table<string, table[]>
local function groupByCategory(plugins)
    local categorized = {}
    for name, info in pairs(plugins) do
        local cat = info.category
        if not categorized[cat] then categorized[cat] = {} end
        table.insert(categorized[cat], { name = name, format = info.format })
    end
    for _, list in pairs(categorized) do
        table.sort(list, function(a, b) return a.name < b.name end)
    end
    return categorized
end

--- Generate a full menuconfig.ini string from a plugin map.
---@param plugins table<string, table>
---@return string
function scanner.generateMenuconfig(plugins)
    local categorized = groupByCategory(plugins)
    local lines = {}
    local function add(line) lines[#lines + 1] = line end

    add("; Auto-generated by LES Plugin Scanner")
    add("; " .. os.date("%Y-%m-%d %H:%M:%S"))
    add("; Feel free to edit, rearrange, or add plugins manually")
    add("")

    local used = {}
    for _, cat in ipairs(CATEGORY_ORDER) do
        local list = categorized[cat]
        if list and #list > 0 then
            used[cat] = true
            add("/" .. cat)
            for _, p in ipairs(list) do
                add(p.name)
                add('"' .. p.name .. '"')
                add("")
            end
        end
    end

    -- Remaining categories
    local remaining = {}
    for cat, _ in pairs(categorized) do
        if not used[cat] then remaining[#remaining + 1] = cat end
    end
    table.sort(remaining)
    for _, cat in ipairs(remaining) do
        local list = categorized[cat]
        if list and #list > 0 then
            add("/" .. cat)
            for _, p in ipairs(list) do
                add(p.name)
                add('"' .. p.name .. '"')
                add("")
            end
        end
    end

    add("")
    add(";V DONT REMOVE THIS OR THE PROGRAM WILL NOT WORK V")
    add("End")
    return table.concat(lines, "\n")
end

--- Extract plugin names already present in menuconfig.ini.
---@return table<string, boolean>  Set of known plugin names (lowercased)
local function getExistingPluginNames()
    local existing = {}
    local menuLines = {}
    local ok = pcall(function() fileToTable("menuconfig.ini", menuLines) end)
    if not ok then return existing end

    for _, line in ipairs(menuLines) do
        if type(line) ~= "string" then goto continue end
        -- Skip comments, categories, separators, control lines
        if line:match("^%s*;") or line:match("^%s*$") or line:match("^/")
           or line:match("^%.%.") or line:match("^%-%-") or line:match("^End")
           or line:match('^"') then
            goto continue
        end
        -- This should be a plugin display name
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            existing[trimmed:lower()] = true
        end
        ::continue::
    end
    return existing
end

--- Append new plugins to existing menuconfig.ini (before the End marker).
--- Only adds plugins not already present. Groups by category.
---@param newPlugins table<string, table>  { [name] = { category, format } }
---@return number  Count of plugins actually appended
function scanner.appendToMenuconfig(newPlugins)
    local existing = getExistingPluginNames()

    -- Filter out plugins already in menuconfig
    local toAdd = {}
    for name, info in pairs(newPlugins) do
        if not existing[name:lower()] then
            toAdd[name] = info
        end
    end

    -- Count
    local count = 0
    for _ in pairs(toAdd) do count = count + 1 end
    if count == 0 then return 0 end

    -- Read current menuconfig.ini
    local menuLines = {}
    fileToTable("menuconfig.ini", menuLines)

    -- Find the "End" marker line index
    local endIdx = nil
    for i = #menuLines, 1, -1 do
        if menuLines[i] and menuLines[i]:find("^End") then
            endIdx = i
            break
        end
    end
    if not endIdx then endIdx = #menuLines + 1 end

    -- Build insertion lines grouped by category
    local categorized = groupByCategory(toAdd)
    local insertLines = {}
    local function add(line) insertLines[#insertLines + 1] = line end

    add("")
    add("; ── New plugins detected " .. os.date("%Y-%m-%d %H:%M") .. " ──")

    for _, cat in ipairs(CATEGORY_ORDER) do
        local list = categorized[cat]
        if list and #list > 0 then
            add("/" .. cat)
            for _, p in ipairs(list) do
                add(p.name)
                add('"' .. p.name .. '"')
                add("")
            end
        end
    end
    -- Remaining categories
    local remaining = {}
    for cat, _ in pairs(categorized) do
        local found = false
        for _, c in ipairs(CATEGORY_ORDER) do
            if c == cat then found = true; break end
        end
        if not found then remaining[#remaining + 1] = cat end
    end
    table.sort(remaining)
    for _, cat in ipairs(remaining) do
        local list = categorized[cat]
        if list and #list > 0 then
            add("/" .. cat)
            for _, p in ipairs(list) do
                add(p.name)
                add('"' .. p.name .. '"')
                add("")
            end
        end
    end

    add("/nocategory")

    -- Insert before End marker
    for i = #insertLines, 1, -1 do
        table.insert(menuLines, endIdx, insertLines[i])
    end

    tableToFile("menuconfig.ini", menuLines)
    return count
end

-- ═══════════════════════════════════════════════════════════════════════
--  User-facing scan actions (called from menu bar)
-- ═══════════════════════════════════════════════════════════════════════

--- Incremental scan: detect new plugins and append to menuconfig.ini.
--- Falls back to full scan if no cache exists.
function scanner.scanAndPrompt()
    local cache = scanner.loadCache()
    local hasCache = cache.scanned_at > 0

    local added, removed, all = scanner.incrementalScan()

    -- Count results
    local addedCount = 0
    for _ in pairs(added) do addedCount = addedCount + 1 end
    local removedCount = 0
    for _ in pairs(removed) do removedCount = removedCount + 1 end
    local totalCount = 0
    for _ in pairs(all) do totalCount = totalCount + 1 end

    if totalCount == 0 then
        HSMakeAlert(
            programName,
            "プラグインが見つかりませんでした。\n\n"
            .. "AU / VST3 プラグインがインストールされているか確認してください。",
            true
        )
        return
    end

    -- First scan (no cache): offer full replacement
    if not hasCache then
        local message = string.format(
            "初回スキャン: %d 個のプラグインを検出しました。\n\n"
            .. "カテゴリ分類済みの menuconfig.ini を生成しますか？\n"
            .. "（現在のファイルはバックアップされます）",
            totalCount
        )
        if HSMakeQuery(programName, message) then
            local timestamp = math.floor(hs.timer.secondsSinceEpoch())
            ShellCopy(
                strJoinPaths(ScriptUserPath, "menuconfig.ini"),
                strJoinPaths(ScriptUserPath, string.format("menuconfig_%d.ini", timestamp))
            )
            local content = scanner.generateMenuconfig(all)
            local f = io.open(GetDataPath("menuconfig.ini"), "w")
            if f then
                f:write(content)
                f:close()
            end
            HSMakeAlert(
                programName,
                string.format(
                    "menuconfig.ini を生成しました（%d プラグイン）\n"
                    .. "バックアップ: menuconfig_%d.ini",
                    totalCount, timestamp
                ),
                true
            )
            reloadLES()
        end
        return
    end

    -- Incremental scan: no changes
    if addedCount == 0 and removedCount == 0 then
        HSMakeAlert(
            programName,
            string.format(
                "変更なし（%d プラグイン検出済み）\n\n"
                .. "新しいプラグインは見つかりませんでした。",
                totalCount
            ),
            true
        )
        return
    end

    -- Incremental scan: changes detected
    local parts = {}
    if addedCount > 0 then
        parts[#parts + 1] = string.format("新規: %d 個", addedCount)
        -- List up to 5 names
        local names = {}
        for name, _ in pairs(added) do
            names[#names + 1] = name
            if #names >= 5 then break end
        end
        table.sort(names)
        for _, n in ipairs(names) do
            parts[#parts + 1] = "  + " .. n
        end
        if addedCount > 5 then
            parts[#parts + 1] = string.format("  ... 他 %d 個", addedCount - 5)
        end
    end
    if removedCount > 0 then
        parts[#parts + 1] = string.format("\nアンインストール済み: %d 個", removedCount)
    end

    local message = table.concat(parts, "\n")
        .. "\n\n新規プラグインを menuconfig.ini に追加しますか？\n（既存のメニュー構成は維持されます）"

    if HSMakeQuery(programName, message) then
        local appended = scanner.appendToMenuconfig(added)
        if appended > 0 then
            HSMakeAlert(
                programName,
                string.format("%d 個のプラグインを menuconfig.ini に追加しました。", appended),
                true
            )
            reloadLES()
        else
            HSMakeAlert(
                programName,
                "追加対象のプラグインはすべて menuconfig.ini に存在していました。",
                true
            )
        end
    end
end

--- Force a full rescan, ignoring cache. Regenerates menuconfig.ini entirely.
function scanner.forceFullScan()
    -- Clear cache to force fresh scan
    scanner.saveCache({ plugins = {}, scanned_at = 0 })
    scanner.scanAndPrompt()
end

return scanner
