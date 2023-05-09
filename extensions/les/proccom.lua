LiveBundleName = "com.ableton.live"

function getLiveHsAppObj()
  return hs.application.find(LiveBundleName)
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
  if string.find(var, LiveBundleName) then
      return true
  else
      return false
  end
end
