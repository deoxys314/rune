local type = type
local floor = math.floor

local misc = {}

function misc.is_integer(n) return type(n) == 'number' and floor(n) == n end

function misc.is_empty(t)
    if type(t) ~= 'table' then
        return nil, 'Not a table!'
    end
    if next(t) then
        return false
    end
    return true
end

return misc
