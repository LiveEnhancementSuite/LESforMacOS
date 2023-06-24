hs.distributednotifications = require("hs.distributednotifications")

-- Storage for a notifications watcher object
distNotWatcher = nil
-- Storage for a timer callback to modify in various tests
testDistNotValue = nil

function testDistributedNotifications()
  distNotWatcher = hs.distributednotifications.new(function(name, object, userInfo)
    if (name == "org.les.Live-Enhancement-Suite.testDistributedNotifications" and
        object == "org.les.Live-Enhancement-Suite.testRunner") then
      testDistNotValue = true
    end
  end, "org.les.Live-Enhancement-Suite.testDistributedNotifications")
  distNotWatcher:start()

  hs.distributednotifications.post("org.les.Live-Enhancement-Suite.testDistributedNotifications", "org.les.Live-Enhancement-Suite.testRunner")

  return success()
end

function testDistNotValueCheck()
  if (type(testDistNotValue) == "boolean" and testDistNotValue == true) then
    return success()
  else
    return string.format("Waiting for success...(%s != true)", tostring(testDistNotValue))
  end
end
