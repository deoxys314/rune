--- A Set of objects.
-- Membership is guaranteed to be unique.
--
-- Several metamethods are implemented to allow manipulation through
-- mathemetical methods.
--
-- Note that Sets are good for containing most types of data except for Sets
-- themselves. Being based on tables, Sets are compared by address equality.
-- @classmod Set
local type = type
local tinsert = table.insert
local setmetatable = setmetatable
local floor = math.floor

local function is_int(n) return type(n) == 'number' and floor(n) == n end

local Set = {}
local InstanceMetatable = {
    __index = Set,
    __name = 'Set',

    --- Convert a Set to a string representation.
    -- @return a string representing the Set.
    __tostring = function(self)
        local string_builder = {'Set {'}
        local len = 0
        for _ in pairs(self) do
            len = len + 1
        end
        local i = 0
        for key, _ in pairs(self) do
            i = i + 1
            tinsert(string_builder, tostring(key))
            if i < len then
                tinsert(string_builder, ', ')
            end
        end
        tinsert(string_builder, '}')
        return table.concat(string_builder)
    end,

    --- Check for Set equality.
    -- Checks that each set contains the same keys exactly.
    -- @return a boolean indicating equality
    __eq = function(self, other)
        -- check that all my keys are in there
        for key, _ in pairs(self) do
            if other[key] == nil then
                return false
            end
        end
        -- and all those keys are in me
        for key, _ in pairs(other) do
            if self[key] == nil then
                return false
            end
        end
        return true
    end,

    --- Union of Sets.
    -- @return a new Set which is a union of the two provided Sets.
    __add = function(first, second)
        local s = Set()
        for k, _ in pairs(first) do
            s[k] = true
        end
        for k, _ in pairs(second) do
            s[k] = true
        end
        return s
    end,
    __sub = function(first, second)
        local s = Set()
        for k, _ in pairs(first) do
            s[k] = true
        end
        for k, _ in pairs(second) do
            s[k] = nil
        end
        return s
    end,

    --- Intersection of Sets.
    -- If either of the parameters is not a Set, then it will be treated as
    -- a Set with just that object as a member. (In fact, that object will be
    -- added to a temporary Set internally.)
    -- The case where neither object is a Set will never occur, because this
    -- metamethod will never be invoked in this case.
    -- @param first Set or object to intresect with second
    -- @param second Set or object to intersect with first
    -- @return a Set which contains the intersection of first and second
    __pow = function(first, second)
        return Set(first):intersection(Set(second))
    end,
}

--- If provided a table, we take this in 2 parts: first we iterate through the
-- array part, keeping track of the largest index we've seen. Then we iterate
-- again through *all* pairs, but ignore integer keys which are smaller than
-- the previously noted larger index. (but keep those above 0, as those are not
-- part of the array).
function Set.new(_, obj)
    local s = {}
    setmetatable(s, InstanceMetatable)
    if type(obj) == 'table' then
        local size = 0
        for idx, value in ipairs(obj) do
            if value and type(value) == 'boolean' then
                s[idx] = true
            else
                s[value] = true
            end
            size = idx
        end
        for key, _ in pairs(obj) do
            if not (is_int(key) and key <= size and key > 0) then
                s[key] = true
            end
        end
    elseif obj ~= nil then
        s[obj] = true
    end
    return s
end

function Set:add(key)
    self[key] = true
    return self
end

function Set:remove(key)
    self[key] = nil
    return self, key
end

function Set:union(other)
    local s = Set()
    for key, _ in pairs(self) do
        s[key] = true
    end
    for key, _ in pairs(other) do
        s[key] = true
    end
    return s
end

function Set:intersection(other)
    local s = Set()
    for key, _ in pairs(self) do
        if other[key] then
            s:add(key)
        end
    end
    return s
end

function Set:difference(other)
    local s = Set()
    for key, _ in pairs(self) do
        s[key] = true
    end
    for key, _ in pairs(other) do
        s[key] = nil
    end
    return s
end

function Set:contains(needle) return self[needle] ~= nil end

function Set:items() return pairs(self) end

local ClassMetatable = {__call = Set.new}

setmetatable(Set, ClassMetatable)

return Set
