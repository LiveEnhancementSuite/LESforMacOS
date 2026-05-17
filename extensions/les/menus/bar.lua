--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

function getMenuBar(debugEnabled, strictEnabled)
  -- Menu bar items and configuration options kept as
  -- a local variable to isolate it from the global context
  local rawBar = {{
    debug = true,
    state = nil,
    title = L("menu_console"),
    fn = function()
      hs.openConsole(true)
    end
  }, {
    debug = true,
    state = nil,
    title = L("menu_restart"),
    fn = function()
      if trackname then
        coolfunc();
      end
      hs.reload()
    end
  }, {
    debug = true,
    state = nil,
    title = L("menu_open_hs_folder"),
    fn = function()
      ShellNSOpen(ScriptUserPath, "Finder")
    end
  }, {
    debug = true,
    state = nil,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = L("menu_search_plugins"),
    fn = function()
      openPluginChooser()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_project_notes"),
    fn = function()
      openProjectNotes()
    end
  }, {
    debug = false,
    state = nil,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = L("menu_ai_assistant"),
    fn = function()
      require("ai.chat").toggle()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_ai_recommend"),
    fn = function()
      require("ai.recommend").open()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_ai_namegen"),
    fn = function()
      require("ai.namegen").open()
    end
  }, {
    debug = false,
    state = nil,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = L("menu_settings"),
    fn = function()
      openSettingsGUI()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_scan_plugins"),
    fn = function()
      local pluginScanner = require("vst.scanner")
      pluginScanner.scanAndPrompt()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_force_rescan"),
    fn = function()
      local pluginScanner = require("vst.scanner")
      pluginScanner.forceFullScan()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_configure_menu"),
    fn = function()
      ShellNSOpen(strJoinPaths(ScriptUserPath, "menuconfig.ini"), "TextEdit")
    end
  }, {
    debug = true,
    state = nil,
    title = L("menu_configure_settings"),
    fn = function()
      ShellNSOpen(strJoinPaths(ScriptUserPath, "settings.ini"), "TextEdit")
    end
  }, {
    debug = false,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = L("menu_project_time"),
    fn = function()
      requesttime()
    end
  }, {
    debug = false,
    state = "off",
    title = L("menu_strict_time"),
    fn = function()
      setstricttime()
    end
  }, {
    debug = false,
    state = nil,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = L("menu_reload"),
    fn = function()
      reloadLES()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_install_insertwhere"),
    fn = function()
      InstallInsertWhere()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_manual"),
    fn = function()
      hs.osascript.applescript(
        [[open location "https://github.com/bassmicrobe/LESforMacOSCustom/blob/develop/docs/USER_MANUAL.md"]])
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_language"),
    fn = function()
      local next = (_G.uiLanguage == "ja") and "en" or "ja"
      settingsManager:writeVal("language", next)
      _G.uiLanguage = next
      reloadLES()
    end
  }, {
    debug = false,
    state = nil,
    title = L("menu_exit"),
    fn = function()
      if trackname then
        coolfunc();
      end
      os.exit()
    end
  }}

  -- Set default arguments
  local debugEnabled = debugEnabled or false
  local strictEnabled = strictEnabled or false

  -- Set "Strict Time" toggle state by menu title (avoids brittle numeric indices when items are added/removed)
  if strictEnabled == true then
    local strictTitle = L("menu_strict_time")
    for idx = 1, #rawBar do
      if rawBar[idx].title == strictTitle then
        rawBar[idx].state = "on"
        break
      end
    end
  end

  -- Construct table depending on debug mode state
  local ret = {}
  for k, v in next, rawBar do
    local entry = {
      state = v.state,
      title = v.title,
      fn = v.fn
    }
    if v.debug == true and debugEnabled == false then
      goto menus_bar_getmenu_continue
    else
      table.insert(ret, entry)
    end
    ::menus_bar_getmenu_continue::
  end
  return ret
end
