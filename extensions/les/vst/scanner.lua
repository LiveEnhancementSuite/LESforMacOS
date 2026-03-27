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
---------------------------------------------------

local scanner = {}

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

-- ── AU type code → LES top-level category mapping ─────────────────────
local AU_TYPE_MAP = {
    ["aufx"] = "Effects",
    ["aumf"] = "Instruments",
    ["aumu"] = "Instruments",
    ["augn"] = "Generator",
    ["aumi"] = "MIDI Effect",
}

--- Classify a plugin name using keyword heuristics.
---@param name string
---@return string|nil  Category name, or nil if no match
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
---@param subcat string  e.g. "Fx|Dynamics|Compressor"
---@return string|nil
function scanner.classifyByVST3Subcat(subcat)
    if not subcat then return nil end
    -- Try most specific match first (longest key)
    for key, cat in pairs(VST3_SUBCAT_MAP) do
        if subcat:find(key, 1, true) then
            return cat
        end
    end
    return nil
end

--- Scan Audio Unit plugins using system_profiler.
--- Returns a list of { name, type, category }.
---@return table
function scanner.scanAU()
    local results = {}
    local handle = io.popen("/usr/sbin/system_profiler SPAudioDataType 2>/dev/null")
    if not handle then return results end
    local output = handle:read("*a")
    handle:close()

    if not output or output == "" then return results end

    -- Parse the system_profiler output
    -- Format:
    --     Plugin Name:
    --       ...
    --       Type: Effect
    --       ...
    local currentName = nil
    for line in output:gmatch("[^\n]+") do
        -- Plugin name lines are indented with spaces and end with ":"
        local pluginName = line:match("^%s%s%s%s(%S.+):$")
        if pluginName then
            currentName = pluginName
        end

        if currentName then
            -- Type line
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
                    topType  = topCat,
                    category = subCat or topCat,
                })
                currentName = nil
            end
        end
    end
    return results
end

--- Scan VST3 plugins by reading moduleinfo.json from .vst3 bundles.
--- Returns a list of { name, category, format }.
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

                    -- Try moduleinfo.json first
                    local category = nil
                    local miPath = bundlePath .. "/Contents/moduleinfo.json"
                    local mf = io.open(miPath, "r")
                    if mf then
                        local raw = mf:read("*a")
                        mf:close()
                        -- Extract subcategories from JSON
                        local subcat = raw:match('"sub_categories"%s*:%s*"([^"]+)"')
                            or raw:match('"subcategories"%s*:%s*%[%s*"([^"]+)"')
                            or raw:match('"category"%s*:%s*"([^"]+)"')
                        category = scanner.classifyByVST3Subcat(subcat)
                    end

                    -- Fallback to keyword heuristic
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

--- Run a full scan: AU + VST3, deduplicate, and return categorized list.
---@return table<string, table[]>  Map of category → list of { name, format }
function scanner.fullScan()
    local auPlugins = scanner.scanAU()
    local vst3Plugins = scanner.scanVST3()

    -- Merge and deduplicate by name (prefer VST3 category if more specific)
    local byName = {}
    for _, p in ipairs(auPlugins) do
        byName[p.name] = { name = p.name, format = p.format, category = p.category }
    end
    for _, p in ipairs(vst3Plugins) do
        local existing = byName[p.name]
        if not existing then
            byName[p.name] = { name = p.name, format = p.format, category = p.category }
        elseif existing.category == "Effects" or existing.category == "Instruments" then
            -- VST3 may have a more specific subcategory
            if p.category ~= "Effects" and p.category ~= "Instruments" then
                existing.category = p.category
                existing.format = existing.format .. "/VST3"
            end
        end
    end

    -- Group by category
    local categorized = {}
    for _, p in pairs(byName) do
        local cat = p.category
        if not categorized[cat] then
            categorized[cat] = {}
        end
        table.insert(categorized[cat], { name = p.name, format = p.format })
    end

    -- Sort plugins within each category
    for _, plugins in pairs(categorized) do
        table.sort(plugins, function(a, b) return a.name < b.name end)
    end

    return categorized
end

--- Generate a categorized menuconfig.ini string from scan results.
---@param categorized table<string, table[]>
---@return string  menuconfig.ini content
function scanner.generateMenuconfig(categorized)
    local lines = {}
    local function add(line) lines[#lines + 1] = line end

    add("; Auto-generated by LES Plugin Scanner")
    add("; " .. os.date("%Y-%m-%d %H:%M:%S"))
    add("; Feel free to edit, rearrange, or add plugins manually")
    add("")

    -- Define a preferred category order
    local categoryOrder = {
        "Instruments", "Synthesizer", "Sampler", "Generator",
        "Compressor", "EQ", "Reverb", "Delay", "Distortion",
        "Modulation", "Pitch", "Mastering", "Utility",
        "MIDI Effect", "Effects",
    }

    local used = {}
    for _, cat in ipairs(categoryOrder) do
        local plugins = categorized[cat]
        if plugins and #plugins > 0 then
            used[cat] = true
            add("/" .. cat)
            for _, p in ipairs(plugins) do
                add(p.name)
                add('"' .. p.name .. '"')
                add("")
            end
        end
    end

    -- Any remaining categories not in the preferred order
    local remainingCats = {}
    for cat, _ in pairs(categorized) do
        if not used[cat] then
            remainingCats[#remainingCats + 1] = cat
        end
    end
    table.sort(remainingCats)
    for _, cat in ipairs(remainingCats) do
        local plugins = categorized[cat]
        if plugins and #plugins > 0 then
            add("/" .. cat)
            for _, p in ipairs(plugins) do
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

--- Run scan and offer to replace menuconfig.ini via dialog.
--- Called from the LES menu bar.
function scanner.scanAndPrompt()
    local categorized = scanner.fullScan()

    -- Count total plugins found
    local total = 0
    local catCount = 0
    for _, plugins in pairs(categorized) do
        total = total + #plugins
        catCount = catCount + 1
    end

    if total == 0 then
        HSMakeAlert(
            programName,
            "プラグインが見つかりませんでした。\n\n"
            .. "AU / VST3 プラグインがインストールされているか確認してください。",
            true
        )
        return
    end

    local message = string.format(
        "%d 個のプラグインを %d カテゴリに分類しました。\n\n"
        .. "現在の menuconfig.ini を置き換えますか？\n"
        .. "（バックアップが自動作成されます）",
        total, catCount
    )

    if HSMakeQuery(programName, message) then
        -- Backup current menuconfig.ini
        local timestamp = math.floor(hs.timer.secondsSinceEpoch())
        ShellCopy(
            strJoinPaths(ScriptUserPath, "menuconfig.ini"),
            strJoinPaths(ScriptUserPath, string.format("menuconfig_%d.ini", timestamp))
        )

        -- Write new menuconfig.ini
        local content = scanner.generateMenuconfig(categorized)
        local f = io.open(GetDataPath("menuconfig.ini"), "w")
        if f then
            f:write(content)
            f:close()
        end

        HSMakeAlert(
            programName,
            string.format(
                "menuconfig.ini を更新しました。\n"
                .. "%d プラグイン / %d カテゴリ\n\n"
                .. "旧ファイルは menuconfig_%d.ini にバックアップ済みです。\n"
                .. "Reload を実行してメニューに反映してください。",
                total, catCount, timestamp
            ),
            true
        )
        reloadLES()
    end
end

return scanner
