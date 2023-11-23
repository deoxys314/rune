# Rune

This is a smallish lua library containing some utility classes and functions.

This project is inspired by many things - by various corners of the Python
standard library, by [Penlight](https://github.com/lunarmodules/Penlight)
libraries, and by my own needs for projects, and my own ideas about what would
be fun or neat to do with lua. As such, while I intend for all provided
functions/classes to be robust and correct, I am unlikely to add something new
unless it will be interesting or useful for me. That said, forking is
encouraged!

## Installation

This project will someday be packaged for distribution via LuaRocks. Until then,
clone this repository somewhere in your `$LUA_PATH` or as part of your project.

## Project Philosophy

This project is arranged with several disparate modules which can be imported as
needed. (E.g. `local Array = require 'rune.Array'`.) Generally the capitalized
names are classes and the uncapitalised names are groupings of related
functions. No modules are interdependent, so you are only importing what you
need. There is also one root module which simply collects everything and you can
then refer to the submodules as needed. E.g.:

```lua
local rune = require 'rune'

local a = rune.Array:new()
for line in io.lines('example') do
  a:append(rune.iterx.sink.collect(rune.stringx.split(line)))
end
```

## Modules

tktkt

### Goals

### Un-goals

## TODO

Goals:

- [x] add a LICENSE file (intended to be MIT)
- [ ] 100% code coverage in testing
- [ ] all public methods and values are documented
- [ ] complete README
- [ ] published to luarocks
- [ ] add [lust](https://github.com/bjornbytes/lust) as a sub-module
  - [ ] upstream improvements to lust
    - [x] pattern matching on stringification of objects
    - [ ] raw equality test
    - [ ] exiting with nonzero codes in case of error

## Credits

This project is formatted with
[lua-format](https://github.com/Koihik/LuaFormatter).

This project is tested with [lust](https://github.com/bjornbytes/lust).

This project is documented with [ldoc](https://github.com/lunarmodules/ldoc)
