--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")

function getLiveHsAppObj()
  return hs.application.find(targetBundle)
end

-- Function for testing if you're in live
-- (this function is retired and is for ease of development mostly)
function checkLiveFocused()
  local var = hs.window.focusedWindow()
  if var ~= nil then
      var = var:application():bundleID()
  else
      return
  end
  if string.find(var, targetBundle) then
      return true
  else
      return false
  end
end

-- TODO: Something less dumb, current "test" involves doing substitutions
--       on the app bundle path till we find a parseable number.
--
--       Someone could just rename the application and this would break.
function getRunningLiveVersion()
  return tonumber(getLiveHsAppObj():path()
                  :gsub(".*/", "")
                  :gsub(".app", "")
                  :gsub("Ableton Live ", "")
                  :gsub(" Suite", "")
                 , 10)
end

-- Creates a table of strings consisting of valid Live menu entries
-- (these include children, which findMenuItem may not necessarily
-- include)
--
-- Use this function sparingly
function getValidTitles()
  function fetchInnerTitle(val, otable)
    local title = val["AXTitle"]
    if val["AXChildren"] ~= nil or title == nil then
      for _key, _val in pairs(val) do
        if type(_val) == "table" then
          fetchInnerTitle(_val, otable)
        end
      end
    else
      if title ~= "" then
        table.insert(otable, title)
      end
    end
  end

  local menuTable = getLiveHsAppObj():getMenuItems()
  local titleTable = {}
  for key, val in pairs(menuTable) do
    if type(val) == "table" then
      fetchInnerTitle(val, titleTable)
    end
  end
  return titleTable
end

function getTipValue(input)
  if type(input) == "table" then
    -- Disregard everything except the last value
    local idx = 0
    for _ in pairs(input) do idx = idx + 1 end
    return input[idx]
  elseif type(input) == "string" then
    return input
  else
    return nil
  end
end

-- selectLiveMenuItem wraps around selectMenuItem and adds
-- validation logic, a menu entry will be selected by the following
-- order of preference before failing:
--
-- a) Explicit name match (fastest)
-- b) Closest valid title match using Lua's string.find (slow)
-- c) Closest match using RegEx after traversal through all menus (slowest, least accurate)
function _selectLiveMenuItem(menuItem)
  -- small sanity check as table is initialized by enablemacros()
  if gValidTitleTable == nil then return false end

  local hsobj = getLiveHsAppObj()
  if hsobj:findMenuItem(menuItem) ~= nil then
    hsobj:selectMenuItem(menuItem)
    return true
  else
    local tipValue = getTipValue(menuItem)

    -- little bit of string sanitation
    tipValue =
    tipValue
      -- accept only alphanumeric characters
      :gsub("[^A-Za-z0-9 ]", "")
      -- strip any remaining spaces before or after phrase
      :match("^%s*(.-)%s*$")

    -- Check through the valid entries table
    for _, val in pairs(gValidTitleTable) do
      -- Convert all to lowercase before checking
      if val:lower():find(tipValue:lower()) then
        if hsobj:findMenuItem(val) ~= nil then
          -- selectMenuItem _is_ case sensitive so we must
          -- pass the value as defined in the table
          hsobj:selectMenuItem(val)
          return true
        end
      end
    end

    -- Can't match with valid entries table, we're really
    -- stuffed... this is a last attempt
    local pattern =
      -- encapsulate phrase into word search regex
      -- Note: selectMenuItem's regex processing is being done by
      --       Hammerspoon which in turn relies on NSPredicate, which
      --       means that we are _not_ using Lua's parser and not
      --       limited by it (also, that means the syntax is
      --       different)
      [[(.*)]] .. tipValue .. [[(.*)]]
    if hsobj:findMenuItem(pattern, true) ~= nil then
      hsobj:selectMenuItem(pattern)
      return true
    end
  end

  -- Something has gone horribly wrong
  return false
end

function selectLiveMenuItem(menuItem)
  if _selectLiveMenuItem(menuItem) == false then
    panicExit(
      string.format(
        [[selectLiveMenuItem(): Attempting to select non-existent menu "%s"]],
        getTipValue(menuItem)
      )
    )
  end
end
