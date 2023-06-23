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
BundleIconPath = QuoteString(JoinPaths(BundleContentPath, AppIcon))

function GetDataPath(string)
    return JoinPaths(ScriptUserPath, string)
end

function GetUserPath(string)
    return JoinPaths(ScriptUserResourcesPath, string)
end

function GetBundleAssetsPath(string)
    return JoinPaths(BundleResourceAssetsPath, string)
end

