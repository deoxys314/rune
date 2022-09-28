--- Pretty-print stuff
-- helper for pprint
local empty = function(t) return next(t) == nil end
local fmt = string.format
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

local mod = {}

local pprint

--- Pretty print objects.
-- notably, this has no protection whatsoever against recursion!
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
        return fmt('%q', object)
    else
        return tostring(object)
    end
end

mod.pprint = pprint

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
