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

-- TODO: Something less dumb, current "test" involves doing substitutions
--       on the app bundle path till we find a parseable number.
--
--       Someone could just rename the application and this would break.
function getRunningLiveVersion()
  return tonumber(getLiveHsAppObj():path()
                  :gsub(".*/", "")
                  :gsub(".app", "")
                  :gsub("Ableton Live ", "")
                  :gsub(" Suite", "")
                 , 10)
end
