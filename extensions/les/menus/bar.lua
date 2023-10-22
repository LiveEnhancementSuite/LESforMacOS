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
    title = "Console",
    fn = function()
      hs.openConsole(true)
    end
  }, {
    debug = true,
    state = nil,
    title = "Restart",
    fn = function()
      if trackname then
        coolfunc();
      end
      hs.reload()
    end
  }, {
    debug = true,
    state = nil,
    title = "Open Hammerspoon Folder",
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
    title = "Configure Menu",
    fn = function()
      ShellNSOpen(strJoinPaths(ScriptUserPath, "menuconfig.ini"), "TextEdit")
    end
  }, {
    debug = false,
    state = nil,
    title = "Configure Settings",
    fn = function()
      ShellNSOpen(strJoinPaths(ScriptUserPath, "settings.ini"), "TextEdit")
    end
  }, {
    debug = false,
    state = nil,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = "Donate",
    fn = function()
        hs.osascript.applescript([[open location "https://www.paypal.me/enhancementsuite"]])
    end
  }, {
    debug = false,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = "Project Time",
    fn = function()
      requesttime()
    end
  }, {
    debug = false,
    state = "off",
    title = "Strict Time",
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
    title = "Reload",
    fn = function()
      reloadLES()
    end
  }, {
    debug = false,
    state = nil,
    title = "Install InsertWhere",
    fn = function()
      InstallInsertWhere()
    end
  }, {
    debug = false,
    state = nil,
    title = "Manual",
    fn = function()
      hs.osascript.applescript([[open location "https://docs.enhancementsuite.me"]])
    end
  }, {
    debug = false,
    state = nil,
    title = "Exit",
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

  -- Mutate "Strict Time" state depending on input
  if strictEnabled == true then
    rawBar[11].state = "on"
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
