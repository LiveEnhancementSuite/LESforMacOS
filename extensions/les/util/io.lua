--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-- Converts a file to a newline-separated index table
function fileToTable(filePath, retTable)
  local fileHdl = io.open(filePath, "r")
  if not fileHdl then
    return
  end
  for _line in fileHdl:lines() do
    table.insert(retTable, _line)
  end
  fileHdl:close()
end

-- Converts an index table into a newline-seperated file
-- WARNING: tableToFile does not append, it overwrites
---@return boolean ok
function tableToFile(filePath, retTable)
  local fileHdl = io.open(filePath, "w")
  if not fileHdl then
    print("tableToFile(): failed to open for write: " .. tostring(filePath))
    return false
  end
  local maxIdx = 0
  for k in pairs(retTable) do
    if type(k) == "number" and k > maxIdx then
      maxIdx = k
    end
  end
  for idx = 1, maxIdx do
    local val = retTable[idx]
    if val ~= nil then
      fileHdl:write(val, "\n")
    end
  end
  fileHdl:flush()
  local ok = fileHdl:close()
  return ok ~= false
end

-- Checks if a file is present
function ioIsFilePresent(fileName)
  local fileHdl = io.open(fileName, "r")
  if fileHdl ~= nil then
      fileHdl:close()
      return true
  else
      return false
  end
end
