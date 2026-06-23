--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("helpers")
require("globals.filenames")

-- Variables determined upon runtime
HomePath = os.getenv("HOME")
BundlePath = hs.processInfo["bundlePath"]

-- Dependent constants
ScriptUserPath = HomePath .. "/.les"
ScriptUserResourcesPath = ScriptUserPath .. "/resources"

BundleContentPath = BundlePath .. "/Contents/Resources"
BundleResourcePath = BundleContentPath .. "/extensions/hs/les"
BundleResourceAssetsPath = BundleResourcePath .. "/assets"
BundleIconPath = strQuote(strJoinPaths(BundleContentPath, AppIcon))

function GetDataPath(path)
    return strJoinPaths(ScriptUserPath, path)
end

function GetUserPath(path)
    return strJoinPaths(ScriptUserResourcesPath, path)
end

function GetBundleAssetsPath(path)
    return strJoinPaths(BundleResourceAssetsPath, path)
end

