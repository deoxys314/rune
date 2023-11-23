--- A Bag or Counter.
-- @classmod MultiSet
local type = type
local setmetatable = setmetatable
local concat = table.concat
local tinsert = table.insert
local format = string.format
local gmatch = string.gmatch
local floor = math.floor

local function is_int(n) return type(n) == 'number' and floor(n) == n end

local MultiSet = {}
local InstanceMetatable = {
    __index = MultiSet,
    __name = 'MultiSet',
    __tostring = function(self)
        local sb = {'MultiSet { '}
        local len = 0
        for _ in pairs(self) do
            len = len + 1
        end
        local iteration = 0
        for key, count in pairs(self) do
            tinsert(sb, format('%s=%d', key, count))
            iteration = iteration + 1
            if iteration < len then
                tinsert(sb, ', ')
            end
        end
        tinsert(sb, ' }')
        return concat(sb)
    end,
    __eq = function(self, other)
        -- check that all my keys are in other
        for key, _ in pairs(self) do
            if other[key] == nil then
                return false
            end
        end
        -- and all the other keys are in me
        for key, _ in pairs(other) do
            if self[key] == nil then
                return false
            end
        end
        -- and that all these keys are equal
        for key, count in pairs(self) do
            if other[key] ~= count then
                return false
            end
        end
        return true
    end,
}

function MultiSet.new(_, obj)
    local m = {}
    setmetatable(m, InstanceMetatable)
    if type(obj) == 'string' then
        for char in gmatch(obj, '.') do
            m[char] = (m[char] or 0) + 1
        end
    elseif type(obj) == 'table' then
        local size = 0
        for idx, value in ipairs(obj) do
            m[value] = (m[value] or 0) + 1
            size = idx
        end
        for key, value in pairs(obj) do
            if not (is_int(key) and key <= size and key > 0) then
                if type(value) == 'number' and is_int(value) then
                    m[key] = (m[key] or 0) + value
                else
                    m[key] = (m[key] or 0) + 1
                end
            end
        end
    elseif obj ~= nil then
        m[obj] = 1
    end

    return m
end

local ClassMetatable = {__call = MultiSet.new}

setmetatable(MultiSet, ClassMetatable)

return MultiSet
