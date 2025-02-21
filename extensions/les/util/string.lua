--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")

function strJoinArgs(str1, str2)
  return str1 .. ARGS_DELIMITER .. str2
end

function strJoinPaths(str1, str2)
    return str1 .. PATH_DELIMITER .. str2
end

function strMultiLineTrim(str)
  local _table = {}
  local retval = ""
  local tmxval = 0
  for line in str:gmatch("[^\r\n]*") do
    table.insert(_table, line)
    tmxval = tmxval + 1
  end
  for idx, t_line in ipairs(_table) do
    local rst = t_line:gsub("^%s*(.-)%s*$", "%1")
    if t_line:find("[^\r\n]*") ~= nil
       and idx ~= 1
       and idx ~= tmxval
    then
      retval = retval .. "\n"
    elseif rst == "" then
      retval = retval .. "\n"
    end
    retval = retval .. rst
  end
  return retval
end

function strQuote(string)
    return [["]] .. string .. [["]]
end

function strSanitize(istr)
  return istr
  -- accept only alphanumeric characters
  :gsub("[^A-Za-z0-9 ]", "")
  -- strip any remaining spaces before or after phrase
  :match("^%s*(.-)%s*$")
end
