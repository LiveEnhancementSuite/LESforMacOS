--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

----------------------------
--  Cheats and eastereggs --
----------------------------

function cheatmenu()
    local button, enteredcheat = hs.dialog.textPrompt(
        L("cheat_title"),
        L("cheat_prompt"),
        "",
        L("btn_ok"),
        L("btn_cancel")
    )
    enteredcheat = enteredcheat:gsub([[.*(.*)%(%"]], "%1")
    enteredcheat = enteredcheat:gsub([[(.*)%".*]], "%1")
    enteredcheat = enteredcheat:lower()
    if button == L("btn_cancel") then
        return false
    elseif button == "Ok" then
        if enteredcheat == "" then
            return false
        elseif enteredcheat == "gaster" then
            os.exit()
        elseif enteredcheat == "collab bro" or enteredcheat == "als" or enteredcheat == "adg" then
            if astBlockingQuery(
                programName,
                [[Doing this will exit your current project without saving. Are you sure?]]
            ) == true then
                getLiveHsAppObj():kill()
                hs.eventtap.keyStroke({"shift"}, "D", 0)
                while true do
                    if getLiveHsAppObj() == nil then
                        break
                    else
                        astSleep(1)
                    end
                end
                print("live is closed")
                ShellCreateDirectory(strJoinPaths(ScriptUserResourcesPath, "als Lessons"))
                ShellCopy(strJoinPaths(BundleResourceAssetsPath, strJoinPaths("als Lessons", "lessonsEN.txt")), strJoinPaths(ScriptUserResourcesPath, "als Lessons"))
                ShellCopy(strJoinPaths(BundleResourceAssetsPath, "als.als"), ScriptUserResourcesPath)
                print("done cloning project")
                hs.osascript.applescript([[delay 2
          tell application "Finder" to open POSIX file "]] .. GetDataPath([[resources/als.als"]]))
                return true
            end

        elseif enteredcheat == "303" or enteredcheat == "sylenth" then
            HSPlayAudioFile(strJoinPaths(BundleResourceAssetsPath, "arp303.mp3"), "thank you for trying this demo")

        elseif enteredcheat == "image line" or enteredcheat == "fl studio" then
            HSPlayAudioFile(strJoinPaths(BundleResourceAssetsPath, "flstudio.mp3"))

        elseif enteredcheat == "ghost" or enteredcheat == "ilwag" or enteredcheat == "lvghst" then
            HSPlayAudioFile(strJoinPaths(BundleResourceAssetsPath, "lvghst.mp3"))

        elseif enteredcheat == "live enhancement sweet" or enteredcheat == "les" or enteredcheat == "sweet" then
            HSPlayAudioFile(strJoinPaths(BundleResourceAssetsPath, "LES_vox.wav"))

        elseif enteredcheat == "yo twitter" or enteredcheat == "twitter" then
            HSPlayAudioFile(strJoinPaths(BundleResourceAssetsPath, "yotwitter.mp3"))
            hs.osascript.applescript([[open location "https://twitter.com/aevitunes"
      open location "https://twitter.com/sylvianyeah"
      open location "https://twitter.com/DylanTallchief"
      open location "https://twitter.com/nyteout"
      open location "https://twitter.com/InvertedSilence"
      open location "https://twitter.com/FalseProdigyUS"
      open location "https://twitter.com/DirectOfficial"]])

        elseif enteredcheat == "owo" or enteredcheat == "uwu" or enteredcheat == "what's this" or enteredcheat == "what" then
            HSMakeAlert(programName, [[owowowowoowoowowowoo what's this????????? ^^ nya?]])

        elseif enteredcheat == "subscribe to dylan tallchief" or enteredcheat == "#dylongang" or enteredcheat ==
            "dylan tallchief" or enteredcheat == "dylantallchief" then
            hs.osascript.applescript([[open location "https://www.youtube.com/c/DylanTallchief?sub_confirmation=1"]])
        end
    end
end

function cheats()
    -- This is the function for the cheats menu. I didn't recreate all of the cheets from the windows version, but I did recreate some of them.
    -- it needs to be up here, because it's used in the reloadLES() routine. Functions need to be declared before they're used.

    if _G.enabledebug == 1 then
        local down1, down2 = false, true
        local press1, press2
        -- this "dingodango" thing keeps track of the user doubletapping both shift keys. cheatmenu() is run when you do.
        dingodango = hs.eventtap.new({hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown},
            function(e)
                local flag = e:rawFlags()
                if flag == 131334 and down1 == false and down2 == true then
                    print("doubleshift press 1")
                    press1 = hs.timer.secondsSinceEpoch()
                    down1 = true
                    down2 = false
                    if press2 ~= nil then
                        if (press1 - press2) < 0.2 then
                            cheatmenu()
                        end
                    end
                elseif flag == 131334 and down1 == true and down2 == false then
                    print("doubleshift press 2")
                    press2 = hs.timer.secondsSinceEpoch()
                    down1 = false
                    down2 = true
                    if (press2 - press1) < 0.2 then
                        cheatmenu()
                    end
                end
            end):start()
    else
        if dingodango then
            dingodango:stop()
        end
    end
end

-----------------
--  Reloading  --
-----------------

function reloadLES()
    -- this function is the heart of the program, reloadLES() (re)builds all of the user configuration.
    -- this is nescesary because restarting hammerspoon is frustratingly slow compared to restarting ahk; so instead I'm manually clearing and rewriting everything when you hit "reload".
    -- reloadLES() is also run a single time on startup to build everything for the first time, standardizing the routine.
    -- all of the functions used here are explained in detail up above.

    clearcategories()
    -- Delete invisible menubar items before dropping refs; otherwise each reload leaks
    -- NSStatusItems and hs.menubar.new() can return nil (main LES icon vanishes).
    if pluginMenu ~= nil then
        pcall(function()
            pluginMenu:delete()
        end)
        pluginMenu = nil
    end
    if pianoMenu ~= nil then
        pcall(function()
            pianoMenu:delete()
        end)
        pianoMenu = nil
    end
    testmenuconfig()
    settingsManager:init()
    settingsManager:parse()
    settingsManager:map()
    buildPluginMenu()
    buildMenuBar()
    rebuildRcMenu()
    if _G.addtostartup == 1 then -- this thing adds a startup daemon for LES when enabled and removes it when you turn it off.
        print("startup = true")
        hs.autoLaunch(true)
        os.execute([[launchctl load "]] .. BundleResourcePath .. [[/assets/live.enhancement.suite.plist"]])
    else
        print("startup = false")
        hs.autoLaunch(false)
        os.execute([[launchctl unload "]] .. BundleResourcePath .. [[/assets/live.enhancement.suite.plist"]])
    end

    -- Launch Agent: watch for Ableton Live and auto-start LES
    local watchPlistDest = os.getenv("HOME") .. "/Library/LaunchAgents/org.les.watch.live.plist"
    if _G.launchwithlive == 1 then
        print("launchwithlive = true")
        local scriptPath = BundleResourcePath .. "/assets/watch_live_launch.sh"
        -- Generate plist with the correct script path
        local plistContent = table.concat({
            [[<?xml version="1.0" encoding="UTF-8"?>]],
            [[<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">]],
            [[<plist version="1.0">]],
            [[<dict>]],
            [[	<key>Label</key>]],
            [[	<string>org.les.watch.live</string>]],
            [[	<key>ProgramArguments</key>]],
            [[	<array>]],
            [[		<string>/bin/bash</string>]],
            [[		<string>]] .. scriptPath .. [[</string>]],
            [[	</array>]],
            [[	<key>RunAtLoad</key>]],
            [[	<true/>]],
            [[	<key>KeepAlive</key>]],
            [[	<true/>]],
            [[	<key>StandardOutPath</key>]],
            [[	<string>/tmp/les-watch-live.log</string>]],
            [[	<key>StandardErrorPath</key>]],
            [[	<string>/tmp/les-watch-live.log</string>]],
            [[</dict>]],
            [[</plist>]],
        }, "\n")
        -- Write plist to ~/Library/LaunchAgents/
        ShellCreateDirectory(os.getenv("HOME") .. "/Library/LaunchAgents")
        local f = io.open(watchPlistDest, "w")
        if f then
            f:write(plistContent)
            f:close()
        end
        os.execute([[launchctl load "]] .. watchPlistDest .. [[" 2>/dev/null]])
    else
        print("launchwithlive = false")
        os.execute([[launchctl unload "]] .. watchPlistDest .. [[" 2>/dev/null]])
        os.remove(watchPlistDest)
    end

    cheats()
end

function quickreload()
    -- this quickreload function is used by the dynamicreload feature. The function is executed right before opening the plugin menu, causing the contents to refresh automatically.
    -- it's shorter, smaller, and thus lighter than the full fat reloadLES() function (which became kind of bloaty over time).
    clearcategories()
    if pluginMenu ~= nil then
        pcall(function()
            pluginMenu:delete()
        end)
        pluginMenu = nil
    end
    if pianoMenu ~= nil then
        pcall(function()
            pianoMenu:delete()
        end)
        pianoMenu = nil
    end
    testmenuconfig()
    buildPluginMenu()
    rebuildRcMenu()
end

function InstallInsertWhere()
    if HSMakeQuery(programName, L("insertwhere_query")) == true then
        HSMakeAlert(programName, L("insertwhere_location_alert"), true)
        local extractLocation = hs.dialog.chooseFileOrFolder(L("insertwhere_folder_dialog"),
            "~/Music/Ableton", false, true, false)
        if extractLocation ~= nil then
            ShellCopy(strJoinPaths(BundleResourceAssetsPath, "InsertWhere.amxd"), extractLocation["1"])
            HSMakeAlert(programName, L("insertwhere_success"), true)
        end
    end
end
