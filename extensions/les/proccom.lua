LiveBundleName = "com.ableton.live"

function getLiveHsAppObj()
  return hs.application.find(LiveBundleName)
end
