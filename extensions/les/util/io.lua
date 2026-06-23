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

-- Converts an index table into a newline-seperated file.
-- WARNING: tableToFile does not append, it overwrites.
-- The write is ATOMIC: contents are written to a sibling temp file and then
-- os.rename()'d over the destination, so an interrupted/failed save never
-- leaves a half-written (corrupt) file behind. os.rename is atomic on the
-- same filesystem; the temp file lives next to the target to guarantee that.
---@param filePath string
---@param retTable table
---@return boolean ok
function tableToFile(filePath, retTable)
  local tmpPath = filePath .. ".tmp"
  local fileHdl = io.open(tmpPath, "w")
  if not fileHdl then
    print("tableToFile(): failed to open for write: " .. tostring(tmpPath))
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
  if ok == false then
    os.remove(tmpPath)
    print("tableToFile(): failed to close temp file: " .. tostring(tmpPath))
    return false
  end
  -- Close the transient-mode window: os.rename replaces the destination inode
  -- with the temp file's (default umask) mode, which would drop an already
  -- secured settings.ini from 600 back to e.g. 644 until secureSettingsFiles()
  -- runs. If the destination already exists, copy its octal mode onto the temp
  -- file FIRST so the secured mode survives the atomic replace. Both paths are
  -- POSIX single-quoted (injection-safe) via strQuote. When the destination is
  -- absent we skip this — the caller (secureSettingsFiles) sets the mode.
  if ioIsFilePresent(filePath) and type(strQuote) == "function" then
    local statHdl = io.popen("stat -f '%Lp' " .. strQuote(filePath) .. " 2>/dev/null")
    if statHdl then
      local mode = (statHdl:read("*l") or ""):match("^(%d+)$")
      statHdl:close()
      if mode then
        os.execute("chmod " .. mode .. " " .. strQuote(tmpPath))
      end
    end
  end
  local renamed, renameErr = os.rename(tmpPath, filePath)
  if not renamed then
    os.remove(tmpPath)
    print("tableToFile(): failed to rename temp over destination: " .. tostring(renameErr))
    return false
  end
  return true
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
