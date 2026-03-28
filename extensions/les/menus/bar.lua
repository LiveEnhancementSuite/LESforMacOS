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
    title = "コンソール",
    fn = function()
      hs.openConsole(true)
    end
  }, {
    debug = true,
    state = nil,
    title = "再起動",
    fn = function()
      if trackname then
        coolfunc();
      end
      hs.reload()
    end
  }, {
    debug = true,
    state = nil,
    title = "Hammerspoon フォルダを開く",
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
    title = "プラグインを検索...",
    fn = function()
      openPluginChooser()
    end
  }, {
    debug = false,
    state = nil,
    title = "プロジェクトノート...",
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
    title = "AI アシスタント...",
    fn = function()
      require("ai.chat").toggle()
    end
  }, {
    debug = false,
    state = nil,
    title = "AI プラグイン提案...",
    fn = function()
      require("ai.recommend").open()
    end
  }, {
    debug = false,
    state = nil,
    title = "AI プロジェクト名提案...",
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
    title = "設定...",
    fn = function()
      openSettingsGUI()
    end
  }, {
    debug = false,
    state = nil,
    title = "プラグインをスキャン...",
    fn = function()
      local pluginScanner = require("vst.scanner")
      pluginScanner.scanAndPrompt()
    end
  }, {
    debug = false,
    state = nil,
    title = "強制フルスキャン...",
    fn = function()
      local pluginScanner = require("vst.scanner")
      pluginScanner.forceFullScan()
    end
  }, {
    debug = false,
    state = nil,
    title = "メニュー設定を編集",
    fn = function()
      ShellNSOpen(strJoinPaths(ScriptUserPath, "menuconfig.ini"), "TextEdit")
    end
  }, {
    debug = true,
    state = nil,
    title = "設定を直接編集 (Raw)",
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
    title = "寄付する",
    fn = function()
        hs.osascript.applescript([[open location "https://www.paypal.me/enhancementsuite"]])
    end
  }, {
    debug = false,
    title = "-"
  }, {
    debug = false,
    state = nil,
    title = "プロジェクト作業時間",
    fn = function()
      requesttime()
    end
  }, {
    debug = false,
    state = "off",
    title = "厳密な時間計測",
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
    title = "再読み込み",
    fn = function()
      reloadLES()
    end
  }, {
    debug = false,
    state = nil,
    title = "InsertWhere をインストール",
    fn = function()
      InstallInsertWhere()
    end
  }, {
    debug = false,
    state = nil,
    title = "マニュアル 📖",
    fn = function()
      hs.osascript.applescript([[open location "https://docs.enhancementsuite.me"]])
    end
  }, {
    debug = false,
    state = nil,
    title = "終了",
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
    rawBar[21].state = "on"
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
