-- this is the scale menu that happens when you double
-- right click while holding shift.

require("menus.keys.chords")
require("menus.keys.scales")

ShiftDoubleRightClickMenu = {{
    menu = {{
        title = "Major/Ionian",
        fn = function()
            _G.stampselect = Major
        end
    }, {
        title = "Natural Minor/Aeolean",
        fn = function()
            _G.stampselect = Minor
        end
    }, {
        title = "Harmonic Minor",
        fn = function()
            _G.stampselect = MinorH
        end
    }, {
        title = "Melodic Minor",
        fn = function()
            _G.stampselect = MinorM
        end
    }, {
        title = "Dorian",
        fn = function()
            _G.stampselect = Dorian
        end
    }, {
        title = "Phrygian",
        fn = function()
            _G.stampselect = Phrygian
        end
    }, {
        title = "Lydian",
        fn = function()
            _G.stampselect = Lydian
        end
    }, {
        title = "Mixolydian",
        fn = function()
            _G.stampselect = Mixolydian
        end
    }, {
        title = "Locrean",
        fn = function()
            _G.stampselect = Locrean
        end
    }, {
        title = "-"
    }, {
        menu = {{
            title = "Major Pentatonic",
            fn = function()
                _G.stampselect = MajorPentatonic
            end
        }, {
            title = "Minor Pentatonic",
            fn = function()
                _G.stampselect = Blues
            end
        }, {
            title = "Major Blues",
            fn = function()
                _G.stampselect = BluesMaj
            end
        }, {
            title = "Minor Blues",
            fn = function()
                _G.stampselect = Blues
            end
        }},
        title = "Pentatonic Based"
    }, {
        menu = {{
            title = "Gypsy",
            fn = function()
                _G.stampselect = Gypsy
            end
        }, {
            title = "Minor Gypsy",
            fn = function()
                _G.stampselect = GypsyM
            end
        }, {
            title = "Arabic/Double Harmonic",
            fn = function()
                _G.stampselect = Arabic
            end
        }, {
            title = "Pelog",
            fn = function()
                _G.stampselect = Pelog
            end
        }, {
            title = "Bhairav",
            fn = function()
                _G.stampselect = Bhairav
            end
        }, {
            title = "Spanish",
            fn = function()
                _G.stampselect = Spanish
            end
        }, {
            title = "-"
        }, {
            title = "Hirajōshi",
            fn = function()
                _G.stampselect = Hirajoshi
            end
        }, {
            title = "In-Sen",
            fn = function()
                _G.stampselect = Insen
            end
        }, {
            title = "Iwato",
            fn = function()
                _G.stampselect = Iwato
            end
        }, {
            title = "Kumoi",
            fn = function()
                _G.stampselect = Kumoi
            end
        }},
        title = "World"
    }, {
        menu = {{
            title = "Chromatic/Freeform Jazz",
            fn = function()
                _G.stampselect = Chromatic
            end
        }, {
            title = "Wholetone",
            fn = function()
                _G.stampselect = Wholetone
            end
        }, {
            title = "Diminished",
            fn = function()
                _G.stampselect = Diminished
            end
        }, {
            title = "Dominant Bebop",
            fn = function()
                _G.stampselect = Dominantbebop
            end
        }, {
            title = "Super Locrian",
            fn = function()
                _G.stampselect = Superlocrian
            end
        }},
        title = "Chromatic"
    }},
    title = "Scales"
}, {
    menu = {{
        title = "Octaves",
        fn = function()
            _G.stampselect = Octaves
        end
    }, {
        title = "Power Chord",
        fn = function()
            _G.stampselect = Powerchord
        end
    }, {
        title = "-"
    }, {
        title = "Major",
        fn = function()
            _G.stampselect = Maj
        end
    }, {
        title = "Minor",
        fn = function()
            _G.stampselect = Min
        end
    }, {
        title = "Maj7",
        fn = function()
            _G.stampselect = Maj7
        end
    }, {
        title = "Min7",
        fn = function()
            _G.stampselect = Min7
        end
    }, {
        title = "Maj9",
        fn = function()
            _G.stampselect = Maj9
        end
    }, {
        title = "Min9",
        fn = function()
            _G.stampselect = Min9
        end
    }, {
        title = "7",
        fn = function()
            _G.stampselect = Dom7
        end
    }, {
        title = "Augmented",
        fn = function()
            _G.stampselect = Aug
        end
    }, {
        title = "Diminished",
        fn = function()
            _G.stampselect = Dim
        end
    }, {
        title = "-"
    }, {
        title = "Triad (Fold)",
        fn = function()
            _G.stampselect = Fold3
        end
    }, {
        title = "Seventh (Fold)",
        fn = function()
            _G.stampselect = Fold7
        end
    }, {
        title = "Ninth (Fold)",
        fn = function()
            _G.stampselect = Fold9
        end
    }},
    title = "Chords"
}}
