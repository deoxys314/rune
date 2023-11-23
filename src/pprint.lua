--- Pretty-print objects
-- @module pprint

local empty = function(t) return next(t) == nil end
local in_list = function(needle, haystack)
    for _, val in ipairs(haystack) do
        if val == needle then
            return true
        end
    end
    return false
end
local rep = string.rep
local spaces = function(level, indent) return rep(' ', level, indent) end

local escapes = {
    ['\a'] = [[\a]],
    ['\b'] = [[\b]],
    ['\f'] = [[\f]],
    ['\n'] = [[\n]],
    ['\r'] = [[\r]],
    ['\t'] = [[\t]],
    ['\v'] = [[\v]],
    ['\\'] = [[\\]],
    ['\"'] = [["]],
    ['\''] = [[']],
}

local mod = {}

local pprint

--- Format objects for pretty-printing.
-- Can handle complex tables reasonably well, and has protection against
-- getting caught in infinite loops when tables have cyclical references.
-- @param object the object to pretty-print
-- @param[type=int,opt=2] indent the number of spaces to indent each level of tables by.
-- @param[type=int,opt=1] level the depth of object currently being displayed.
-- This rarely needs to be set by an end-user.
-- @param[type=table,opt={}] seen_tables tables which have already been
-- rendered and will be replaced with a notation that a cycle has been
-- detected. This also rarely needs to be set by an end-user.
-- @return a string representation of the object
pprint = function(object, indent, level, seen_tables)
    -- The last three arguments are optional, and are mainly used internally

    -- set defaults if not provided
    local mylevel = level or 1
    local myindent = indent or 2
    local myseen_tables = seen_tables or {}

    -- begin string construction
    local s = ''
    if type(object) == 'table' then
        if in_list(object, myseen_tables) then
            return '... (cycle)'
        else
            table.insert(myseen_tables, object)
        end
        if empty(object) then
            return '{}'
        else
            s = s .. '{\n'
            for k, v in pairs(object) do
                if type(k) ~= 'number' then
                    k = '"' .. k .. '"'
                end
                s = s .. spaces(mylevel * myindent) .. '[' .. k .. '] = ' ..
                        pprint(v, mylevel + 1, myindent, myseen_tables) .. ',\n'
            end
            return s .. spaces((mylevel - 1) * myindent) .. '}'
        end
    elseif type(object) == 'string' then
        return '"' ..  string.gsub(object, '%c', escapes) .. '"'
        -- return fmt('%q', string.gsub(object, '%c', escapes))
    else
        return tostring(object)
    end
end

mod.pprint = pprint

--- Pretty-print objects.
-- Uses @{pprint} to format objects and immediately dumps them to stdout with
-- @{io.write}.
-- @function dump
-- @param obj the object to dump
-- @return nil
mod.dump = function(obj)
    io.write(pprint(obj))
    io.write('\n')
end

setmetatable(mod, {
    __call = function(_t, obj, indent, level, seen_tables)
        return pprint(obj, indent, level, seen_tables)
    end,
})

return mod
