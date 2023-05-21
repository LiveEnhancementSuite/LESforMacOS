--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-- Program constants
programName = "Live Enhancement Suite"
programBundle = "org.les.Live-Enhancement-Suite"
programVersion = "dill"
programBugTracker = "https://github.com/LiveEnhancementSuite/LESforMacOS/issues"

-- macOS 10.15 (Catalina)
programMinTarget = 10.15

-- macOS switched from incrementing minor release values to major release
-- values with Big Sur, so we now set the minor version to 99 to make sure 
-- that update releases don't set off validation warnings
--
-- macOS 13 (Ventura)
programMaxTarget = 13.99

-- Target constants
targetName = "Live"
targetBundle = "com.ableton.live"
targetMinVersion = 9
targetMaxVersion = 11
