--------------
--	Scales	--
--------------

-- Ok so, I'm not gonna lie. This part of the script is a complete mess.
-- Basically, these are all the keystrokes that are executed when you
-- place a scale using the piano-roll macro. I didn't bother to make a
-- function for them, probably for performance reasons, so they're just
-- all down here in the form of walls of text.
--
-- If you want to add extra scales, you can - it's pretty easy to see what's
-- going on here. Just make sure to add the function to the menu contents
-- table at the top of the script.

Major = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Minor = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

MinorH = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

MinorM = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Dorian = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Phrygian = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Lydian = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Mixolydian = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Locrean = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Blues = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

BluesMaj = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Arabic = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Gypsy = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Diminished = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Dominantbebop = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Wholetone = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

-- push scales start

Superlocrian = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Bhairav = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

GypsyM = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Hirajoshi = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Insen = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Iwato = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Kumoi = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Pelog = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

Spanish = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end
-- push scales end

Chromatic = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

MajorPentatonic = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end

MinorPentatonic = function()
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
    hs.eventtap.keyStroke({"cmd"}, "C", 0);
    hs.eventtap.keyStroke({"cmd"}, "V", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0);
    hs.eventtap.keyStroke({}, "Up", 0)
end
