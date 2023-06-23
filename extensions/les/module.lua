--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("helpers")
require("settings")

module = {
  -- TODO: migrate globals here
}

function module.initState(self)
  -- Converts a file to a newline-separated index table
  function fileToTable(filePath, retTable)
    local fileHdl = io.open(filePath, "r")
    for _line in fileHdl:lines() do
      table.insert(retTable, _line)
    end
    fileHdl:close()
  end

  -- Converts an index table into a newline-seperated file
  -- WARNING: tableToFile does not append, it overwrites
  function tableToFile(filePath, retTable)
    local fileHdl = io.open(filePath, "w")
    for idx, val in ipairs(retTable) do
      fileHdl:write(val, "\n")
    end
    fileHdl:close()
  end

::module_load_settings::
  -- It could be possible that this might be invoked more than once
  -- (see the nice goto marker above) so we should clear our loaded
  -- values from the table
  for key, val in pairs(settingsManager) do
    if type(val) == "table" then
      settingsManager[key]["value"] = nil
    end
  end

  local settingsFile = {}
  fileToTable("settings.ini", settingsFile)
  settingsManager:load(settingsFile)

  -- Check if every settings value has been loaded from the configuration file
  local valuesAllLoaded = true
  local valuesPending = {}
  for key, val in pairs(settingsManager) do
    -- We're only interested in inspecting values, not functions
    if type(val) == "table" then
      if settingsManager:getVal(key) == nil then
        valuesAllLoaded = false
        table.insert(valuesPending, key)
        print(string.format("module.initState(): unable to load \"%s\", not defined in settings.ini", key))
      end
    end
  end

  if valuesAllLoaded == false then
    -- Backup current settings file
    ShellCopy(
      JoinPaths(ScriptUserPath, "settings.ini"),
      JoinPaths(ScriptUserPath, string.format("settings_%d.ini", math.floor(hs.timer.secondsSinceEpoch())))
    )

    -- Write defaults to settings file in memory
    for idx, val in ipairs(valuesPending) do
      local skey = val
      local sval = settingsManager[val]["default"]
      -- Print out the description of the setting 'key'
      for _idx, _val in ipairs(settingsManager[val]["desc"]) do
        table.insert(settingsFile, string.format("; %s", _val))
      end
      -- Print out the expected default pair
      table.insert(settingsFile, string.format("%s = %s", skey, sval))
      print(string.format("module.initState(): setting \"%s\" to \"%s\" in settings table", skey, sval))
      -- Add newline to distinguish between each setting
      table.insert(settingsFile, "")
    end

    -- Flush settings file to disk
    tableToFile("settings.ini", settingsFile)
    print("module.initState(): flushed settings.ini to disk, reattempting to load configuration file")
    -- Re-load configuration file and hope 'valuesAllLoaded' is true this time
    goto module_load_settings
  end

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

-- TODO: get rid of this eventually
--       once all invocations are contained
function module.initCompatLogic(self)
  _G.autoadd = settingsManager["autoadd"]["value"]
  _G.loadspeed = settingsManager["loadspeed"]["value"]
  _G.resettobrowserbookmark = settingsManager["resettobrowserbookmark"]["value"]
  _G.bookmarkx = settingsManager["bookmarkx"]["value"]
  _G.bookmarky = settingsManager["bookmarky"]["value"]
  _G.disableloop = settingsManager["disableloop"]["value"]
  _G.saveasnewver = settingsManager["saveasnewver"]["value"]
  _G.altgrmarker = settingsManager["altgrmarker"]["value"]
  _G.double0todelete = settingsManager["double0todelete"]["value"]
  _G.absolutereplace = settingsManager["absolutereplace"]["value"]
  _G.ctrlabsoluteduplicate = settingsManager["ctrlabsoluteduplicate"]["value"]
  _G.enableclosewindow = settingsManager["enableclosewindow"]["value"]
  _G.vstshortcuts = settingsManager["vstshortcuts"]["value"]
  _G.dynamicreload = settingsManager["dynamicreload"]["value"]
  _G.pianorollmacro = settingsManager["pianorollmacro"]["value"]
  _G.texticon = settingsManager["texticon"]["value"]
  _G.addtostartup = settingsManager["addtostartup"]["value"]
  _G.enabledebug = settingsManager["enabledebug"]["value"]
end

function module.init(self)
  self:initState()
  self:initCompatLogic()
end
