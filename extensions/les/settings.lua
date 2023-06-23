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
  ["checksanity"]             = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin", 
                                  ["desc"] = { "Toggles validation of supported macOS and Ableton Live versions" } },
}

function settingsManager.bind(self)
  -- Avoid touching functions
  for key, val in pairs(self) do
    if type(val) == "table" then
      self[key]["value"] = nil
    end
  end
end

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

function settingsManager.map(self)
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
  _G.checksanity = settingsManager["checksanity"]["value"]
end

function settingsManager.init(self)
  -- Clear loaded values because we could be called multiple times
  self:bind()

  -- Create new settings file if it doesn't exist
  if ioIsFilePresent(GetDataPath("settings.ini")) == false then
    ShellCreateEmptyFile(GetDataPath("settings.ini"))
  end

  -- Read settings file and load it
  local settingsFile = {}
  fileToTable("settings.ini", settingsFile)
  self:load(settingsFile)

  -- Check if every settings value has been loaded from the configuration file
  local valuesAllLoaded = true
  local valuesPending = {}
  for key, val in pairs(self) do
    -- We're only interested in inspecting values, not functions
    if type(val) == "table" then
      if self:getVal(key) == nil then
        valuesAllLoaded = false
        table.insert(valuesPending, key)
        print(string.format("settingsManager.init(): unable to load \"%s\", not defined in settings.ini", key))
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
      local sval = self[val]["default"]
      -- Print out the description of the setting 'key'
      for _idx, _val in ipairs(self[val]["desc"]) do
        table.insert(settingsFile, string.format("; %s", _val))
      end
      -- Print out the expected default pair
      table.insert(settingsFile, string.format("%s = %s", skey, sval))
      print(string.format("settingsManager.init(): setting \"%s\" to \"%s\" in settings table", skey, sval))
      -- Add newline to distinguish between each setting
      table.insert(settingsFile, "")
    end

    -- Flush settings file to disk
    tableToFile("settings.ini", settingsFile)
    print("settingsManager.init(): flushed settings.ini to disk, reattempting to load configuration file")
    -- Re-load configuration file and hope 'valuesAllLoaded' is true this time
    self:init()
  end
end

function settingsManager.parse(self)
  function setautoadd(newval)
    local hFile = io.open(GetDataPath("settings.ini"), "r") -- Reading settings.
    local restOfFile
    local lineCt = 1
    local newline = "addtostartup = " .. newval .. [[]]
    local lines = {}
    for line in hFile:lines() do
      if string.find(line, "addtostartup =") then -- Is this the line to modify?
        -- print(newline)
        lines[#lines + 1] = newline -- Change old line into new line.
        restOfFile = hFile:read("*a")
        break
      else
        lineCt = lineCt + 1
        lines[#lines + 1] = line
      end
    end
    hFile:close()

    hFile = io.open(GetDataPath("settings.ini"), "w") -- write the file.
    for i, line in ipairs(lines) do
      hFile:write(line, "\n")
    end
    hFile:write(restOfFile)
    hFile:close()
  end

  -- We are relying on module.init further down the line to make sure
  -- this code path isn't erroneously called again
  if ioIsFilePresent(GetDataPath("resources/firstrun.txt")) == false then
    if HSMakeQuery(
      programName, [[
        You're all set! Would you like to set LES to launch on login? (this can be changed later)
      ]]
    ) == true then 
      setautoadd(1)
    else
      setautoadd(0)
    end
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
