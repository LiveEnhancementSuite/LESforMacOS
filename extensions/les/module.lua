--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")
require("helpers")
require("settings")
require("util.io")

module = {
  -- TODO: migrate globals here
}

function module.parseSettings(self)
  if settingsManager:getVal("pianorollmacro") == nil
     or hs.keycodes.map[
        -- We need to explicitly make sure that it is passed as a string
        -- as possible evaluation as a number will return the keycode mapped by
        -- index rather than corresponding keyboard key
        tostring(settingsManager:getVal("pianorollmacro"))
      ] == nil
     and _G.nomacro == nil
  then
    -- there is an alternate error message here because the generic one confused too many people.
    HSMakeAlert(programName, [[
        Hey! The settings entry for "pianorollmacro" is not a character corresponding to a key on your keyboard.

        Closing this dialog box will open the settings file for you; please change the character under "pianorollmacro" to a key that exists on your keyboard and then restart the program.

        You won't be able to properly use many features without it.

        LES will continue to run without a proper pianoroll macro mapped.
    ]], true, "critical")
    ShellNSOpen(JoinPaths(ScriptUserPath, "settings.ini"), "TextEdit")
    _G.nomacro = true
  else
    -- We're not doing the assignment through setVal because
    -- while "pianorollmacro" _is_ stored as a string, we substitute
    -- the global from the configuration value to its equivalent hammerspoon
    -- mapping code, which is numerical and _not_ the same as the 
    -- configuration value
    --
    -- TODO: Make the corresponding keycode a distinct variable so we can offer
    --       reset capabilities
    settingsManager["pianorollmacro"]["value"] = 
      tonumber(
        hs.keycodes.map[
          tostring(settingsManager:getVal("pianorollmacro"))
        ]
      )
    _G.nomacro = false
  end
end

function module.init(self)
  settingsManager:init()
  self:parseSettings()
  -- Map to values to global keys
  -- TODO: Get rid of this once all values are queried with getVal
  settingsManager:map()
end
