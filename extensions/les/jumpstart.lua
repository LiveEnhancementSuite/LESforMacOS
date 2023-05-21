--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

console = hs.appfinder.windowFromWindowTitle("Hammerspoon Console")
currentdir = hs.fs.currentDir()

if console then
    console:close()
end -- attempts to close the console if it's up
print(currentdir)

-- enables the dock icon while initializing
hs.dockIcon(true)
hs.menuIcon(false)
hs.uploadCrashData(false)
hs.openConsoleOnDockClick(true)
-- don't update hammerspoon and undo all my changes, please!
hs.automaticallyCheckForUpdates(false)

bundlePath = hs.processInfo["bundlePath"]

package.path = package.path .. ";" .. bundlePath .. [[/Contents/Resources/extensions/hs/les/?.lua]]
dofile(bundlePath .. [[/Contents/Resources/extensions/hs/les/LESmain.lua]])
