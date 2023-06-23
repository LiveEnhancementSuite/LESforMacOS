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
  ["autoadd"]                 = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["resettobrowserbookmark"]  = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin" },
  ["disableloop"]             = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["saveasnewver"]            = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["altgrmarker"]             = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["double0todelete"]         = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["absolutereplace"]         = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["ctrlabsoluteduplicate"]   = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin" },
  ["enableclosewindow"]       = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["vstshortcuts"]            = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["dynamicreload"]           = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin" },
  ["texticon"]                = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin" },
  ["addtostartup"]            = { ["value"] = nil, ["default"] = "0"  , ["type"] = "bin" },
  ["enabledebug"]             = { ["value"] = nil, ["default"] = "1"  , ["type"] = "bin" },
  ["pianorollmacro"]          = { ["value"] = nil, ["default"] = "§"  , ["type"] = "str" },
  ["bookmarkx"]               = { ["value"] = nil, ["default"] = "500", ["type"] = "int" },
  ["bookmarky"]               = { ["value"] = nil, ["default"] = "500", ["type"] = "int" },
  ["loadspeed"]               = { ["value"] = nil, ["default"] = "0.3", ["type"] = "flt" },
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
