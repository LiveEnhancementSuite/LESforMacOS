--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")
require("helpers")
require("settings")
require("util.io")

module = {
  -- TODO: migrate globals here
}

function module.init(self)
  settingsManager:init()
  settingsManager:parse()
  -- Map to values to global keys
  -- TODO: Get rid of this once all values are queried with getVal
  settingsManager:map()
end
