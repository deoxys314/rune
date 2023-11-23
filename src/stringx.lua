--- String utility functions.
-- @module stringx
local gmatch = string.gmatch
local match = string.match

local stringx = {}

--- Split a string.
-- Splits a string by whitespace or a user-defined pattern.
-- @param[type=string] input string to split
-- @param[type=string,opt='%s'] separator lua pattern to split on
-- @return an iterator of the words separated by the pattern (similar to gmatch and friends)
function stringx.split(input, separator)
    local sep = separator or [[%s]]
    return gmatch(input, '([^' .. sep .. ']+)')
end

--- Iterate over the characters of a string.
-- @usage for char in stringx.chars('Hello World!') do
--     io.write(char)
-- end
-- @param[type=string] input the string to iterate over
-- @return an iterator over each character of the input string
function stringx.chars(input)
    return gmatch(input, '.')
end
--- Iterare over the words of a string.
-- This is defined as groups of non-whitespace characters. If you wish to
-- specifically only look at groups of numbers or letters or similar, your own
-- invocation of `string.gmatch` may be needed.
-- @param[type=string] input string to iterate over the words of
-- @return an iterator over the words in the string
function stringx.words(input)
    return gmatch(input , [[%S+]])
end

--- Remove whitespace from the beginning and end of a string.
-- Remove characters lua considers whitespace from the beginning or end of
-- a string. Can have slow performace in pathological cases, such as a string
-- of all whitespace.
-- @param[type=string] input string to trim
-- @return the trimmed string
function stringx.trim(input)
    return match(input, [[^%s*(.*%S)]]) or ''
end

return stringx
