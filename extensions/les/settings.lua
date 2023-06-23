--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")
require("helpers")

-- TODO: use default keys to allow repairing the settings
--       file without forcing a complete rewrite of its values
settingsManager = {
  ["autoadd"]                 = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Automatically add plugins after looking them up" } },
  ["resettobrowserbookmark"]  = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin",
                                  ["desc"] = { "Optional feature where LES will click a certain point on your screen after using the menu.",
                                               "This can be used to click a collection, or close a browser", "",
                                               "Due to limitations in macOS, this feature is only enabled on fullscreen mode" } },
  ["disableloop"]             = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "This prevents the loop button from being enabled by default in MIDI clips created",
                                               "with the Cmd + Shift + M shortcut" } },
  ["saveasnewver"]            = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Toggles the cmd + alt + s shortcut that duplicates and saves your project as a new version",
                                               "similar to FL Studio. The syntax is in this format [project name]_[version]" } },
  ["altgrmarker"]             = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Switches the marker shortcut from Shift + L to Alt + L",
                                               "It is recommended to keep this on in the mac version if you like capitalising letters" } },
  ["double0todelete"]         = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Toggles the double 0 to delete shortcut" } },
  ["absolutereplace"]         = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Toggles the shortcuts Ctrl + Alt + D and Ctrl + Alt + V", "",
                                               "It's best to disable this feature if you want to use video in your project files since",
                                               "Ctrl + Alt + V is actually a taken shortcut in this scenario" } },
  ["ctrlabsoluteduplicate"]   = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin",
                                  ["desc"] = { "Maps the absolute duplicate shortcut to Cmd + Ctrl + D if you don't want to disable or",
                                               "overwrite the default dock hide/unhide shortcut on Preferences > Keyboard > Shortcuts" } },
  ["enableclosewindow"]       = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Toggles the Ctrl + W and Ctrl + Shift + W shortcuts" } },
  ["vstshortcuts"]            = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin",
                                  ["desc"] = { "Toggles the suite of VST specific shortcuts" } },
  ["dynamicreload"]           = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin",
                                  ["desc"] = { "Setting that sets LES to refresh menuconfig.ini contents every time the menu is opened",
                                               "Not recommended to be used alongside large config files. Performance hit depends on hardware" } },
  ["texticon"]                = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin",
                                  ["desc"] = { "Replaces the menubar icon graphic in the top right with text saying \"LES\"" } },
  ["addtostartup"]            = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin",
                                  ["desc"] = { "Sets LES to launch on login" } },
  ["enabledebug"]             = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin",
                                  ["desc"] = { "Toggles access to debug options used for development, such as the console" } },
  ["pianorollmacro"]          = { ["value"] = nil, ["default"] = "§"  , ["type"] = "str",
                                  ["desc"] = { "The key that is used as the piano roll macro", "",
                                               "If you want to remap the piano roll macro, remove the set value and then replace it",
                                               "with the character that the key you want to remap it to corresponds to without modifiers", "",
                                               "So if you want to remap it to the 1 key, just type \"1\"" } },
  ["bookmarkx"]               = { ["value"] = nil, ["default"] = "500", ["type"] = "int",
                                  ["desc"] = { "The X coordinates (in pixels) which is clicked at, selected at random"} },
  ["bookmarky"]               = { ["value"] = nil, ["default"] = "500", ["type"] = "int",
                                  ["desc"] = { "The Y coordinates (in pixels) which is clicked at, selected at random" } },
  ["loadspeed"]               = { ["value"] = nil, ["default"] = "0.3", ["type"] = "flt",
                                  ["desc"] = { "Amount of seconds it takes for LES to attempt to add the item after looking it up", "",
                                               "Increase this value if you have a slow hard disk, which could cause LES to try to add",
                                               "items before they've been found" } },
}

function settingsPanicAndExit(message, range)
  panicExit(
    string.format([[settingsPanicAndExit(): Value for "%s" is not %s]], message, range),
    function()
      ShellNSOpen(JoinPaths(ScriptUserPath, "settings.ini"), "TextEdit")
    end
  )
end

function settingsManager.getVal(self, key)
  return self[key]["value"]
end

function settingsManager.setVal(self, key, value)
  local _type = self[key]["type"]
  if _type == "int"
     or _type == "flt"
     or _type == "bin"
  then
    if
      tonumber(value) ~= nil
    then
      self[key]["value"] = tonumber(value)
    else
      panicExit(
        string.format(
          [[setVal(): unable to parse value "%s" for key "%s" of type %s as valid number]],
          value, key, _type
        )
      )
    end
  else
    self[key]["value"] = value
  end
end

function settingsManager.load(self, fileTable)
  -- TODO: allow termination logic to have a graceful shutdown.
  --       currently, validateValue either returns true or kills
  --       the program.
  function validateValue(key, value, type)
    local valMap = {
      ["bin"] = { ["sign"] = "%d",
                  ["error"] =
                    function()
                      settingsPanicAndExit(key, "a number between 0 and 1")
                    end,
                  ["validate"] =
                    function()
                      local _value = tonumber(value)
                      return _value == 1 or _value == 0
                    end
                  },
      ["int"] = { ["sign"] = "%d",
                  ["error"] =
                    function()
                      settingsPanicAndExit(key, "a number higher than 0")
                    end,
                  ["validate"] =
                    function()
                      return tonumber(value) > 0
                    end },
      ["flt"] = { ["sign"] = "%d%.%d",
                  ["error"] =
                    function()
                      settingsPanicAndExit(key, "a valid floating point number")
                    end,
                  ["validate"] =
                    function()
                      return tonumber(value) ~= nil
                    end },
      ["str"] = { ["sign"] = "%s",
                  ["error"] = function() return true end,
                  ["validate"] = function() return true end }
    }
    if
      string.match(value, valMap[type]["sign"])
    then
      if
        not valMap[type]["validate"]()
      then
        valMap[type]["error"]()
      end
    end
    return true
  end

  for idx = 1, #fileTable, 1 do
    local line = fileTable[idx];
    -- skip unparseable lines
    if
      -- empty line
      line == nil
      -- autohotkey syntax comments
      or string.find(line, ";")
      -- end declarations
      or string.find(line, "End")
    then
      goto continue_strmgr_loop
    end
    -- start parsing all valid entries
    for key, val in pairs(self) do
      -- is key and delimiter present
      if
        -- functions are first class data types in lua and so the k/v pair
        -- will include function definitions, we can avoid this by checking
        -- if the value in the pair is a table or not
        type(val) == "table" and
        string.find(line, key) and string.find(line, "=")
      then
        print(string.format("%s found", key))
        -- extract value and validate
        local _val = line:gsub(".*(.*)%=%s", "%1")
        if
          validateValue(key, _val, self[key]["type"])
        then
          -- set internal state if validation passed
          self:setVal(key, _val)
        end
      end
    end
    ::continue_strmgr_loop::
  end
end
