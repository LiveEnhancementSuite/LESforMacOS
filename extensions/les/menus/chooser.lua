--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-----------------------------------------
--  Plugin Search UI (hs.chooser)      --
--  Spotlight-style incremental search --
-----------------------------------------

---@type hs.chooser|nil
local pluginChooser = nil

--- Recursively collect all plugin entries from the menu table.
--- Each entry has { text, subText, fn } where fn is the pre-baked loadPlugin closure.
---@param menuTable table
---@param category string  Human-readable breadcrumb, e.g. "Synths › Analog"
---@param results table
local function collectPlugins(menuTable, category, results)
    if type(menuTable) ~= "table" then return end
    for _, item in ipairs(menuTable) do
        if type(item) ~= "table" then goto continue end
        local title = item.title
        if title == nil or title == "-" then goto continue end

        if type(item.fn) == "function" then
            -- Leaf node: this is an actual plugin entry
            table.insert(results, {
                text    = title,
                subText = (category ~= "" and category or "プラグイン"),
                fn      = item.fn,
            })
        elseif type(item.menu) == "table" then
            -- Submenu: recurse with updated breadcrumb
            local subCat = (category ~= "") and (category .. " › " .. title) or title
            collectPlugins(item.menu, subCat, results)
        end
        ::continue::
    end
end

--- Open a Spotlight-style plugin chooser.
--- Reads the global `menu` table built by buildPluginMenu().
--- On selection, activates Live then calls the item's loadPlugin closure.
function openPluginChooser()
    if menu == nil then
        hs.alert.show("プラグインメニューがまだ読み込まれていません")
        return
    end

    -- Collect all leaf (plugin) entries
    local choices = {}
    collectPlugins(menu, "", choices)

    if #choices == 0 then
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

    pluginChooser:choices(choices)
    pluginChooser:placeholderText("プラグインを検索...")
    pluginChooser:searchSubText(true)
    pluginChooser:rows(12)
    pluginChooser:width(45)
    pluginChooser:show()
end
