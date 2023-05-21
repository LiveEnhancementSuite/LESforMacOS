--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

bundlePath = hs.processInfo["bundlePath"]
package.path = package.path .. ";" .. bundlePath .. [[/Contents/Resources/extensions/hs/les/?.lua]]
dofile(bundlePath .. [[/Contents/Resources/extensions/hs/les/LESmain.lua]])
