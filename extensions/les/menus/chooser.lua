--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-----------------------------------------
--  Plugin Search UI (hs.chooser)      --
--  Category filter + sort by stats    --
-----------------------------------------

local pluginStats = require("tracking.pluginstats")

---@type hs.chooser|nil
local pluginChooser = nil

--- Current sort mode and category filter (persist across opens within session)
local currentSort = "name"         -- "name" | "frequency" | "recent" | "added"
local currentCategory = nil        -- nil = all, string = specific category

--- Recursively collect all plugin entries from the menu table.
--- Each entry has { text, subText, category, fn }.
---@param menuTable table
---@param category string  Human-readable breadcrumb
---@param results table
local function collectPlugins(menuTable, category, results)
    if type(menuTable) ~= "table" then return end
    for _, item in ipairs(menuTable) do
        if type(item) ~= "table" then goto continue end
        local title = item.title
        if title == nil or title == "-" then goto continue end

        if type(item.fn) == "function" then
            table.insert(results, {
                text     = title,
                subText  = (category ~= "" and category or "プラグイン"),
                category = category,
                fn       = item.fn,
            })
        elseif type(item.menu) == "table" then
            local subCat = (category ~= "") and (category .. " › " .. title) or title
            collectPlugins(item.menu, subCat, results)
        end
        ::continue::
    end
end

--- Extract unique top-level categories from choices.
---@param choices table
---@return table  Sorted list of category names
local function extractCategories(choices)
    local seen = {}
    local cats = {}
    for _, c in ipairs(choices) do
        local topCat = c.category
        if topCat ~= "" then
            -- Extract top-level category (before first " › ")
            local top = topCat:match("^([^›]+)") or topCat
            top = top:match("^%s*(.-)%s*$")
            if not seen[top] then
                seen[top] = true
                cats[#cats + 1] = top
            end
        end
    end
    table.sort(cats)
    return cats
end

--- Sort choices by the given mode using plugin stats.
---@param choices table
---@param sortMode string
---@return table  New sorted table
local function sortChoices(choices, sortMode)
    local stats = pluginStats.getAll()
    local sorted = {}
    for i, c in ipairs(choices) do
        sorted[i] = c
    end

    if sortMode == "frequency" then
        table.sort(sorted, function(a, b)
            local sa = stats[a.text]
            local sb = stats[b.text]
            local ca = sa and sa.use_count or 0
            local cb = sb and sb.use_count or 0
            if ca ~= cb then return ca > cb end
            return a.text < b.text
        end)
    elseif sortMode == "recent" then
        table.sort(sorted, function(a, b)
            local sa = stats[a.text]
            local sb = stats[b.text]
            local la = sa and sa.last_used_at or 0
            local lb = sb and sb.last_used_at or 0
            if la ~= lb then return la > lb end
            return a.text < b.text
        end)
    elseif sortMode == "added" then
        table.sort(sorted, function(a, b)
            local sa = stats[a.text]
            local sb = stats[b.text]
            local aa = sa and sa.added_at or 0
            local ab = sb and sb.added_at or 0
            if aa ~= ab then return aa > ab end
            return a.text < b.text
        end)
    else
        -- "name" — alphabetical
        table.sort(sorted, function(a, b)
            return a.text < b.text
        end)
    end
    return sorted
end

--- Format subText with stats info for display.
---@param choice table
---@param stats table  All stats data
---@return string
local function formatSubText(choice, stats)
    local parts = {}
    parts[#parts + 1] = choice.subText or "プラグイン"

    local s = stats[choice.text]
    if s then
        if s.use_count and s.use_count > 0 then
            parts[#parts + 1] = string.format("使用: %d回", s.use_count)
        end
        if s.last_used_at and s.last_used_at > 0 then
            parts[#parts + 1] = "最終: " .. os.date("%m/%d %H:%M", s.last_used_at)
        end
    end
    return table.concat(parts, "  |  ")
end

--- Build chooser-compatible choices from raw plugin list.
---@param allChoices table  Raw collected plugins
---@param catFilter string|nil  Category filter (nil = all)
---@param sortMode string  Sort mode
---@return table  Formatted choices for hs.chooser
local function buildChoices(allChoices, catFilter, sortMode)
    -- Filter by category
    local filtered
    if catFilter then
        filtered = {}
        for _, c in ipairs(allChoices) do
            local topCat = c.category:match("^([^›]+)") or c.category
            topCat = topCat:match("^%s*(.-)%s*$")
            if topCat == catFilter then
                filtered[#filtered + 1] = c
            end
        end
    else
        filtered = allChoices
    end

    -- Sort
    local sorted = sortChoices(filtered, sortMode)

    -- Format for hs.chooser with stats in subText
    local stats = pluginStats.getAll()
    local result = {}
    for _, c in ipairs(sorted) do
        result[#result + 1] = {
            text    = c.text,
            subText = formatSubText(c, stats),
            fn      = c.fn,
        }
    end
    return result
end

--- Open the favorites manager chooser.
--- Displays all plugins with ★/☆ prefix; selecting one toggles its favorite state.
---@param allChoices table  Raw plugin list
local function openFavoritesChooser(allChoices)
    local function buildFavChoices()
        local favChoices = {}
        for _, c in ipairs(allChoices) do
            local isFav = pluginStats.isFavorite(c.text)
            favChoices[#favChoices + 1] = {
                text    = (isFav and "★ " or "☆ ") .. c.text,
                subText = isFav and "お気に入り登録済み" or c.subText or "プラグイン",
                plugin  = c.text,
            }
        end
        table.sort(favChoices, function(a, b) return a.text < b.text end)
        return favChoices
    end

    local favChooser
    favChooser = hs.chooser.new(function(choice)
        if choice == nil then
            openPluginChooser()
            return
        end
        pluginStats.toggleFavorite(choice.plugin)
        -- Reopen with refreshed state
        hs.timer.doAfter(0.05, function()
            favChooser:choices(buildFavChoices())
            favChooser:show()
        end)
    end)
    favChooser:choices(buildFavChoices())
    favChooser:placeholderText("お気に入りを切り替え...")
    favChooser:searchSubText(false)
    favChooser:rows(14)
    favChooser:width(55)
    favChooser:show()
end

--- Open the sort selection chooser.
---@param allChoices table  Raw plugin list (for rebuilding main chooser)
local function openSortChooser(allChoices)
    local sortOptions = {
        { text = "名前順 (A→Z)",         subText = "アルファベット順で表示",     mode = "name" },
        { text = "使用頻度順",            subText = "よく使うプラグインを上位に", mode = "frequency" },
        { text = "最終使用日時順",         subText = "最近使ったプラグインを上位に", mode = "recent" },
        { text = "追加日時順",            subText = "新しく追加されたプラグインを上位に", mode = "added" },
    }

    local sortChooser = hs.chooser.new(function(choice)
        if choice == nil then
            -- User cancelled — reopen main chooser with current settings
            openPluginChooser()
            return
        end
        currentSort = choice.mode
        openPluginChooser()
    end)
    sortChooser:choices(sortOptions)
    sortChooser:placeholderText("ソート方法を選択...")
    sortChooser:rows(4)
    sortChooser:width(45)
    sortChooser:show()
end

--- Open the category filter chooser.
---@param allChoices table  Raw plugin list
local function openCategoryChooser(allChoices)
    local categories = extractCategories(allChoices)
    local catOptions = {
        { text = "すべて表示", subText = "カテゴリフィルタを解除", cat = nil },
    }
    for _, cat in ipairs(categories) do
        catOptions[#catOptions + 1] = { text = cat, subText = "カテゴリ", cat = cat }
    end

    local catChooser = hs.chooser.new(function(choice)
        if choice == nil then
            openPluginChooser()
            return
        end
        currentCategory = choice.cat
        openPluginChooser()
    end)
    catChooser:choices(catOptions)
    catChooser:placeholderText("カテゴリを選択...")
    catChooser:rows(math.min(#catOptions, 12))
    catChooser:width(45)
    catChooser:show()
end

--- Open a Spotlight-style plugin chooser.
--- Reads the global `menu` table built by buildPluginMenu().
--- Supports category filter and sort by usage stats.
function openPluginChooser()
    if menu == nil then
        hs.alert.show("プラグインメニューがまだ読み込まれていません")
        return
    end

    -- Collect all leaf (plugin) entries
    local allChoices = {}
    collectPlugins(menu, "", allChoices)

    if #allChoices == 0 then
        hs.alert.show("menuconfig.ini にプラグインが見つかりません")
        return
    end

    -- Destroy any existing chooser instance
    if pluginChooser ~= nil then
        pluginChooser:delete()
        pluginChooser = nil
    end

    pluginChooser = hs.chooser.new(function(choice)
        if choice == nil then return end

        -- Handle special actions
        if choice.action == "sort" then
            openSortChooser(allChoices)
            return
        elseif choice.action == "category" then
            openCategoryChooser(allChoices)
            return
        elseif choice.action == "favorites" then
            openFavoritesChooser(allChoices)
            return
        end

        -- Activate Live before triggering loadPlugin so Cmd+F hits Live
        hs.timer.doAfter(0.05, function()
            local liveApp = getLiveHsAppObj and getLiveHsAppObj()
            if liveApp then
                liveApp:activate()
                hs.timer.doAfter(0.1, function()
                    if type(choice.fn) == "function" then
                        choice.fn()
                    end
                end)
            else
                if type(choice.fn) == "function" then
                    choice.fn()
                end
            end
        end)
    end)

    -- Build action bar items at the top
    local sortLabels = { name = "名前順", frequency = "頻度順", recent = "最終使用順", added = "追加日時順" }
    local statusParts = { "ソート: " .. (sortLabels[currentSort] or "名前順") }
    if currentCategory then
        statusParts[#statusParts + 1] = "カテゴリ: " .. currentCategory
    end

    local favoriteNames = pluginStats.getFavorites()
    local favLabel = #favoriteNames > 0 and (tostring(#favoriteNames) .. "件") or "なし"

    local actionItems = {
        { text = "⚙ ソート変更",     subText = table.concat(statusParts, "  |  "), action = "sort" },
        { text = "📂 カテゴリ絞込",   subText = currentCategory and ("現在: " .. currentCategory) or "すべて表示中", action = "category" },
        { text = "⭐ お気に入り管理", subText = "お気に入り: " .. favLabel, action = "favorites" },
    }

    -- Build favorite choices (shown above the main list)
    local stats = pluginStats.getAll()
    local favoriteChoices = {}
    for _, name in ipairs(favoriteNames) do
        -- Find the matching choice entry to get its fn
        for _, c in ipairs(allChoices) do
            if c.text == name then
                favoriteChoices[#favoriteChoices + 1] = {
                    text    = "★ " .. c.text,
                    subText = formatSubText(c, stats),
                    fn      = c.fn,
                }
                break
            end
        end
    end

    -- Build main choices
    local mainChoices = buildChoices(allChoices, currentCategory, currentSort)

    -- Combine: actions → favorites (if any) → all plugins
    local finalChoices = {}
    for _, a in ipairs(actionItems) do
        finalChoices[#finalChoices + 1] = a
    end
    if #favoriteChoices > 0 then
        for _, f in ipairs(favoriteChoices) do
            finalChoices[#finalChoices + 1] = f
        end
    end
    for _, c in ipairs(mainChoices) do
        finalChoices[#finalChoices + 1] = c
    end

    pluginChooser:choices(finalChoices)
    pluginChooser:placeholderText("プラグインを検索...")
    pluginChooser:searchSubText(true)
    pluginChooser:rows(14)
    pluginChooser:width(55)
    pluginChooser:show()
end
