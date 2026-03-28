--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

------------------------
--  Integrity checks  --
------------------------

-- these functions check the if the files nescesary for the script to function; exist.
-- hammerspoon completely spaces out of they don't.
-- I declare them up here because it fits the theme of this section of the script.

function testmenuconfig()
    local var = ioIsFilePresent(GetDataPath("menuconfig.ini"))

    if var == false then
        if HSMakeQuery(programName, L("menuconfig_missing"), "critical") == true then
            ShellCopy(strJoinPaths(BundleResourcePath, MenuConfigFile), ScriptUserPath .. PATH_DELIMITER)
        else
            os.exit()
        end
    end
end

-- this is what happens when you hit "readme" in the default plugin menu.

function readme()
    HSPlayAudioFile(strJoinPaths(BundleResourceAssetsPath, "readmejingle.wav"))
    HSMakeAlert(programName, L("readme_body"))
end

-------------------------------------
--  digesting the menuconfig file  --
-------------------------------------

-- Direct helped make me recreate the original AHK menu file parser in lua before I got started on the project.
-- While it's the first part of the program we made, it's the last thing that worked.
-- This part of the code will always be difficult to comprehend for me, so I figure it's basically impossible to understand you.
-- Turn back while you still can.

-- notice how I'm just declaring function; it's executed later when I run reloadLES().

function buildPluginMenu()

    local file = io.open("menuconfig.ini", "r")
    if file == nil then
        print("buildPluginMenu(): menuconfig.ini not found")
        return
    end

    -- Read all lines at once (faster than per-line table.insert)
    local arr = {}
    local arrLen = 0
    for line in file:lines() do
        arrLen = arrLen + 1
        arr[arrLen] = line
    end
    file:close()

    if pluginArray ~= nil then
        local delcount = #pluginArray
        for i = 1, delcount do
            pluginArray[i] = nil
        end
    end
    if menu ~= nil then
        local delcount = #menu
        for i = 1, delcount do
            menu[i] = nil
        end
    end

    -- Reverses the Array in-place
    local j, k = 1, arrLen
    while j < k do
        arr[j], arr[k] = arr[k], arr[j]
        j = j + 1
        k = k - 1
    end

    local readmevar = false

    -- Cache frequently used functions as locals for hot loop
    local sfind = string.find
    local ssub = string.sub
    local sgsub = string.gsub
    local slen = string.len
    local smatch = string.match
    local tinsert = table.insert
    local tremove = table.remove

    for i = arrLen, 1, -1
    do
        arr[i] = sgsub(arr[i], "\xe2\x80\x9c", "\"")
        if arr[i] == "\xe2\x80\x94\r" or arr[i] == "-\n" or arr[i] == "\xe2\x80\x94" then
            arr[i] = "--"
            tinsert(arr, i, "--")
        elseif slen(arr[i]) < 2 and not smatch(arr[i], "%w") then
            tremove(arr, i)
        elseif arr[i] == nil then
            tremove(arr, i)
        elseif sfind(arr[i], ";") == 1 then
            tremove(arr, i)
        elseif smatch(arr[i], "Readme") or smatch(arr[i], "readme") then
            readmevar = true
            tremove(arr, i)
        elseif sfind(arr[i], "%-%-") == 1 then
            tinsert(arr, i, "--")
        elseif sfind(arr[i], "End") then
            tremove(arr, i)
        elseif sfind(arr[i], "") then
        end
    end

    local subfolderval = 0
    local subfoldername = ""
    local subfolderuponelevel = ""
    local subfolderhistory = {}
    pluginArray = {}

    -- Pre-allocate pluginArray capacity hint (reduces table resizing)
    local pluginIdx = 0

    for i = #arr, 1, -1 do
        local line = arr[i]
        local firstChar = ssub(line, 1, 1)
        local firstTwo = ssub(line, 1, 2)

        if sfind(firstChar, "/") and not sfind(firstTwo, "//") and
            not sfind(line, "nocategory") then
            subfoldername = sgsub(line, '', '')
            tinsert(subfolderhistory, subfoldername)
            subfolderval = 1
            local entry = subfolderval .. ", " .. subfoldername .. ", " .. "❗️"
            pluginIdx = pluginIdx + 1
            pluginArray[pluginIdx] = entry
            pluginIdx = pluginIdx + 1
            pluginArray[pluginIdx] = entry
            tremove(arr, i)
        elseif sfind(firstTwo, "//") then
            tinsert(subfolderhistory, subfoldername)
            subfoldername = sgsub(line, '', '')
            local _, count = sgsub(line, "%/", "")
            subfolderval = count
            local entry = subfolderval .. ", " .. subfoldername .. ", " .. "❗️"
            pluginIdx = pluginIdx + 1
            pluginArray[pluginIdx] = entry
            pluginIdx = pluginIdx + 1
            pluginArray[pluginIdx] = entry
            tremove(arr, i)
        elseif sfind(firstTwo, "%.%.") then
            subfoldername = subfolderhistory[subfolderval]
            subfolderval = subfolderval - 1
        elseif sfind(line, "/nocategory") then
            subfolderval = 0
            tremove(arr, i)
        else
            pluginIdx = pluginIdx + 1
            pluginArray[pluginIdx] = subfolderval .. ", " .. subfoldername .. ", " .. line
        end
    end

    -- Split function with cached locals
    local sgmatch = string.gmatch
    local function mysplit(inputstr)
        if inputstr == nil then return end
        local t = {}
        local idx = 1
        for str in sgmatch(inputstr, "([^,]+)") do
            t[idx] = str
            idx = idx + 1
        end
        return t
    end

    local function RemoveSlashes(str, scope)
        local newstring = str:gsub("^%s*(.-)%s*$", "%1")
        newstring = ssub(newstring, scope + 1)
        return newstring
    end

    local lastLevel = 0
    local level = 0
    local lastcatagoryName = "menu"
    local scopes = {}
    local categorycount = nil
    local categoryhistory = {}

    for i = 1, #pluginArray, 2 do
        if pluginArray[i] == nil then
            table.remove(pluginArray, i)
            goto pls
        end
        if pluginArray[i + 1] == nil then
            table.remove(pluginArray, (i + 1))
            goto pls
        end

        local level = tonumber(string.sub(pluginArray[i], 1, 1))

        local thisIndex = mysplit(pluginArray[i])
        local nextIndex = mysplit(pluginArray[i + 1])
        local categoryName = RemoveSlashes(thisIndex[2], level)

        -- RUNS RIGHT AT THE START IF A PLUGIN IS INSERTED FIRST IN THE MENU
        if i == 1 and level == 0 then
            if _G[lastcatagoryName] == nil then
                _G[lastcatagoryName] = {}
            end

            if string.find(string.sub(pluginArray[i], 1, 2), "%-%-") or
                string.find(string.sub(pluginArray[i], 1, 2), "\xe2\x80\x94") then
                table.insert(_G[lastcatagoryName], {title = "-"})
            else
                table.insert(_G[lastcatagoryName], {
                    title = string.sub(thisIndex[3], 2),
                    fn = function()
                        loadPlugin(nextIndex[3])
                    end
                }) -- inserts the first plugin
            end
            -- RUNS RIGHT AT THE START IF A FOLDER IS INSERTED FIRST IN THE MENU
        elseif i == 1 and level == 1 then
            if _G[lastcatagoryName] == nil then
                _G[lastcatagoryName] = {}
            end
            if string.find(nextIndex[3], "❗️") then
                _G[categoryName] = {} -- don't insert the !
            else
                _G[categoryName] = {
                    title = string.sub(thisIndex[3], 2),
                    fn = function()
                        loadPlugin(nextIndex[3])
                    end
                }
            end

            if string.find(string.sub(pluginArray[i], 1, 2), "%-%-") or
                string.find(string.sub(pluginArray[i], 1, 2), "-") then
                table.insert(_G[lastcatagoryName], {title = "-"})
            else
                table.insert(_G[lastcatagoryName], {title = categoryName, menu = _G[categoryName]})
            end
            table.insert(scopes, lastcatagoryName)
            -- THIS IS IF WE GO BACK TO THE ROOT FOLDER AFTER BEING IN A SUBFOLDER
        elseif level == 0 then
            if string.find(string.sub(thisIndex[3], 1, 4), "%-%-") or
                string.find(string.sub(thisIndex[3], 1, 4), "%\xe2\x80\x94") then
                table.insert(menu, {title = "-"})
            else
                table.insert(menu, {
                    title = string.sub(thisIndex[3], 2),
                    fn = function()
                        loadPlugin(nextIndex[3])
                    end
                }) -- inserts the first plugin
            end

            -- Up scope
        elseif level > lastLevel then
            if _G[lastcatagoryName] == nil then
                _G[lastcatagoryName] = {}
            end

            if string.find(nextIndex[3], "❗️") then
                _G[categoryName] = {}
            else
                _G[categoryName] = {
                    title = string.sub(thisIndex[3], 2),
                    fn = function()
                        loadPlugin(nextIndex[3])
                    end
                }
            end

            if string.find(string.sub(pluginArray[i], 1, 2), "%-%-") or
                string.find(string.sub(pluginArray[i], 1, 2), "\xe2\x80\x94") then
                table.insert(_G[lastcatagoryName], {title = "-"})
            else
                table.insert(_G[lastcatagoryName], {title = categoryName, menu = _G[categoryName]}) -- Inserts the new menu
            end
            table.insert(scopes, lastcatagoryName)

            -- Same scope
        elseif level == lastLevel and categoryName == lastcatagoryName then
            if string.find(pluginArray[i], "%-%-") or string.find(pluginArray[i], "\xe2\x80\x94") then
                table.insert(_G[categoryName], {title = "-"})
            else
                table.insert(_G[categoryName], {
                    title = string.sub(thisIndex[3], 2),
                    fn = function()
                        loadPlugin(nextIndex[3])
                    end
                }) -- inserts plugin
            end

            -- Same scope new folder
        elseif level == lastLevel and categoryName ~= lastcatagoryName then
            table.remove(scopes, level + 1)
            if _G[categoryName] == nil then
                _G[categoryName] = {}
            end

            if string.find(string.sub(pluginArray[i], 1, 2), "%-%-") or
                string.find(string.sub(pluginArray[i], 1, 2), "\xe2\x80\x94") then
                table.insert(_G[scopes[level]], {title = "-"})
            else
                table.insert(_G[scopes[level]], {title = categoryName, menu = _G[categoryName]}) -- Inserts the new menu
            end

            -- Down scope with new folder
        elseif level < lastLevel and categoryName ~= lastcatagoryName then
            if scopes[level] == "menu" then
                scopes = {"menu"}
            end
            if _G[categoryName] == nil then
                _G[categoryName] = {}
                table.insert(_G[scopes[level]], {title = categoryName, menu = _G[categoryName]}) -- Inserts the new menu
            end

            if string.find(string.sub(pluginArray[i], 1, 2), "%-%-") or
                string.find(string.sub(pluginArray[i], 1, 2), "\xe2\x80\x94") then
                table.insert(_G[categoryName], {title = "-"})
            else
                if string.find(nextIndex[3], "❗️") then
                    table.insert(_G[categoryName], {}) -- inserts plugin
                else
                    table.insert(_G[categoryName], {
                        title = string.sub(thisIndex[3], 2),
                        fn = function()
                            loadPlugin(nextIndex[3])
                        end
                    }) -- inserts plugin
                end
            end

            -- Down scope
        elseif level < lastLevel and categoryName == lastcatagoryName then
            if _G[categoryName] == nil then
                _G[categoryName] = {}
            end
            if string.find(string.sub(pluginArray[i], 1, 2), "%-%-") or
                string.find(string.sub(pluginArray[i], 1, 2), "\xe2\x80\x94") then
                table.insert(_G[categoryName], {title = "-"})
            else
                table.insert(_G[categoryName], {
                    title = string.sub(thisIndex[3], 2),
                    fn = function()
                        loadPlugin(nextIndex[3])
                    end
                }) -- inserts plugin
            end
        end
        lastLevel = level
        -- this conditional basically checks if we are 'home' and if we are
        -- then we last category = menu.
        if categorycount == nil then
            categorycount = 0 -- 0 because the count is increased to 1 by the first item causing the first entry to be nil (it's a stupid workaround)
            categoryhistory = {}
        end

        if lastLevel == 0 then
            lastcatagoryName = "menu"
        else
            if lastcatagoryName ~= nil then -- this part of the code keeps track of all the subfolder names, so they can be cleared later; preventing double entires on reloadLES()
                if lastcatagoryName ~= categoryName then
                    categorycount = (categorycount + 1)
                end
            end
            lastcatagoryName = categoryName
            _G.categoryhistory_list = _G.categoryhistory_list or {}
            _G.categoryhistory_list[categorycount] = lastcatagoryName
        end

        ::pls::
    end

    if readmevar == true then
        table.insert(menu, {
            title = L("plugin_readme"),
            fn = function()
                readme()
            end
        })
    end
end

function clearcategories()
    -- this part of the code goes back through the folder structure history to clear all folders before rebuilding the menu again.
    -- this prevents double entries from showing up after reloadLES() was executed.
    if _G.categoryhistory_list ~= nil then
        print("category history exists")
        for i = 1, #_G.categoryhistory_list, 1 do
            _G[_G.categoryhistory_list[i]] = nil
        end
        _G.categoryhistory_list = nil
    end
end

---------------------------------
--  Creating menubar contents  --
---------------------------------

function buildMenuBar() -- this function makes the menu bar happen, the one that pops up when you click the icon in the top right.
    if LESmenubar ~= nil then
        LESmenubar:delete()
    end -- this is me trying to clear it properly, but as experience has shown; hammerspoon doesn't properly garbage collect these well so I'm not sure if it even matters.
    LESmenubar = hs.menubar.new()
    LESmenubar:setMenu(getMenuBar(_G.enabledebug == 1, _G.stricttimevar))
    if _G.texticon == 1 then
        LESmenubar:setTitle("LES")
    else
        LESmenubar:setIcon(BundleResourcePath .. "/assets/osxTrayIcon.png", true) -- cool icon :sunglasses:
    end
end

function rebuildRcMenu()
    -- This function rebuilds the right click menus inside ableton.
    -- The right click menu's are actually just menu bar items, but they're invisible.
    -- Both the pianomenu and the plugin menu are (re)loaded.
    if pluginMenu ~= nil then
        pluginMenu:delete()
    end
    pluginMenu = hs.menubar.new()
    pluginMenu:setMenu(menu)
    pluginMenu:setTitle("LES")
    pluginMenu:removeFromMenuBar()

    if pianoMenu ~= nil then
        pianoMenu:delete()
    end
    pianoMenu = hs.menubar.new()
    pianoMenu:setMenu(ShiftDoubleRightClickMenu)
    pianoMenu:setTitle("Piano")
    pianoMenu:removeFromMenuBar()
end
