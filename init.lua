--- Module containing some useful classes and helpers to extend the
-- minimal Lua standard library.

--- Constants
-- @section constants
local rune = {
    _author = "Cameron Rossington",
    _author_email = "deoxys314@gmail.com",
    --- Table containing version information.
    _version = { major = 0, minor = 1, patch = 0 },
    --- String containing version information.
    _version_string = "0.1.0"
}

--- Utility classes
-- @section classes

--- Class for array-like tables, inspired by Python's list class.
rune.Array = require 'rune.src.Array'

--- Class for hash-like tables.
rune.HashMap = require 'rune.src.Hashmap'

--- Class for Sets, containers with unique contents.
rune.Set = require 'rune.src.Set'

--- Class for MultiSets, containers with counts of unique constants.
-- Inspired by Python's collections.Counter.
rune.MultiSet = require 'rune.src.MultiSet'

--- Utility functions
-- @section functions

--- Pretty-printing of complex objects.
rune.pprint = require 'rune.src.pprint'

--- String utility functions.
rune.stringx = require 'rune.src.stringx'

--- Table utility functions.
rune.tablex = require 'rune.src.tablex'

-- Some more lazy, functional iterator functions
rune.iterx = require 'rune.src.iterx'

rune.misc = require 'rune.src.misc'

return rune
