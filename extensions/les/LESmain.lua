--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-- Compatibility code used to upgrade LES's jumpstart routine if we're upgrading from
-- older versions. To be retained for a maximum of two releases, after which it should
-- be removed. We will not be including any modules defined by LES so we're going to be
-- pretending the routines we defined don't exist.

require("util.locale")

-- CODE START
function launchBashScript(script)
  local handle = io.popen(
    [[/bin/bash -c ']] .. script .. [[']]
  )
  local retcode = {handle:close()}
  return tonumber(retcode[3])
end

function shouldMigrate()
  local fileHdl = io.open(os.getenv("HOME") .. "/.les/init.lua", "r")
  if fileHdl ~= nil then
      fileHdl:close()
      return launchBashScript(
        [[cmp "${HOME}/.les/init.lua" "]] .. hs.processInfo["bundlePath"] .. [[/Contents/Resources/extensions/hs/les/jumpstart.lua"]]
      ) > 0
  else
      return false
  end
end

if shouldMigrate() == true then
  if
  hs.dialog.blockAlert(
    "Live Enhancement Suite",
    L("jumpstart_mismatch"),
    L("btn_yes"),
    L("btn_no")
  ) == L("btn_yes")
  then
    -- User has accepted repair
    if launchBashScript(
[[
#!/usr/bin/env bash
set -eux
mv "${HOME}/.les/init.lua" "${HOME}/.les/init.lua.bak";
cp "]] .. hs.processInfo["bundlePath"] .. [[/Contents/Resources/extensions/hs/les/jumpstart.lua" "${HOME}/.les/init.lua";
exit 0;
]]
    ) == 0 then
      -- Repair has succeeded
      hs.dialog.blockAlert("Live Enhancement Suite", L("jumpstart_success"), L("btn_ok"), "")
      os.exit()
    else
      -- Repair has failed
      hs.dialog.blockAlert("Live Enhancement Suite", L("jumpstart_failure"), L("btn_ok"), "")
      os.exit()
    end
  else
    -- User has refused repair, prompt for application exit
    if hs.dialog.blockAlert("Live Enhancement Suite", L("jumpstart_continue_warning"), L("btn_yes"), L("btn_no")) == L("btn_yes") then
      -- User has chosen to exit
      os.exit()
    end
    -- User has chosen to continue despite warnings, unsupported
  end
end

-- Un-define functions and free up variables
launchBashScript = nil
shouldMigrate = nil
-- CODE END

---------------------------------
--  Core module initialization --
---------------------------------

require("module")
require("helpers")
require("menus.bar")
require("menus.keys.menu")
require("globals.constants")
require("globals.filepaths")
require("proccom")
require("util.io")
require("ui.hud")
require("menus.chooser")
require("menus.settingsgui")
require("tracking.projectnotes")
require("tracking.notifications")
require("ui.cheatsheet")
require("ai.openai")
require("ai.chat")
require("ai.recommend")
require("ai.namegen")

module:init()

---------------------------
--  Stock menu contents  --
---------------------------

local filepath = GetDataPath("resources/strict.txt")
local f = io.open(filepath, "r")
if f ~= nil then
    io.close(f)
    _G.stricttimevar = true
else
    _G.stricttimevar = false
end

-----------------------------------------------
--  Split modules: menus, lifecycle, reload  --
-----------------------------------------------

require("menus.plugin")
require("lifecycle.reload")

reloadLES() -- when the script reaches this point, reloadLES is executed for a first time - finally actually doing all the stuff up above.

---------------------------------------------
--  Split modules: shortcuts, VST, macros  --
---------------------------------------------

require("shortcuts.macros")
require("shortcuts.rightclick")
require("vst.shortcuts")
require("shortcuts.piano")

---------------------------------------------
--  Split modules: tracking, app lifecycle --
---------------------------------------------

require("tracking.timer")
require("lifecycle.appwatch")
