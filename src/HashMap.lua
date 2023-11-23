--- A Dictionary-like table.
-- @classmod HashMap
local setmetatable = setmetatable
local tinsert = table.insert
local format = string.format

local HashMap = {}
local InstanceMetatable = {
    __index = HashMap,
    __name = 'HashMap',

    __tostring = function(self)
        local sb = {'HashMap {'}
        local count = 0
        for _ in pairs(self) do
            count = count + 1
        end
        local iteration = 0
        for key, value in pairs(self) do
            tinsert(sb, format('%s=%s', key, value))
            iteration = iteration + 1
            if iteration < count then
                tinsert(sb, ', ')
            end
        end
        tinsert(sb, '}')
        return table.concat(sb)
    end,

    __eq = function(self, other)
        for key, _ in pairs(self) do
            if other[key] == nil then
                return false
            end
        end
        for otherkey, _ in pairs(other) do
            if self[otherkey] == nil then
                return false
            end
        end
        for key, value in pairs(self) do
            if other[key] ~= value then
                return false
            end
        end
        return true
    end,

    __add = function(first, second)
        local h = HashMap()
        if type(first) == 'table' then
            h:update(first)
        end
        if type(second) == 'table' then
            h:update(second)
        end
        return h
    end,
}
local ClassMetatable = {}

setmetatable(HashMap, ClassMetatable)

function HashMap.new(_, obj)
    local h = {}
    setmetatable(h, InstanceMetatable)
    if type(obj) == 'table' then
        for key, value in pairs(obj) do
            h[key] = value
        end
    end
    return h
end

ClassMetatable.__call = HashMap.new

function HashMap:add(key, value)
    self[key] = value
    return self
end

function HashMap:update(tbl)
    if type(tbl) == 'table' then
        for key, value in pairs(tbl) do
            self[key] = value
        end
    end
    return self
end

function HashMap.initialize(n, f, ...)
    local h = HashMap()
    local func = f or function(num) return num, num end
    for i = 1, n do
        local key, value = func(i, ...)
        h:add(key, value)
    end
    return h
end

function HashMap:map(f, ...)
    local h = HashMap()
    for key, value in pairs(self) do
        h:add(key, f(key, value, ...))
    end
    return h
end

function HashMap:filter(f, ...)
    local h = HashMap()
    for key, value in pairs(self) do
        if f(key, value, ...) then
            h:add(key, value)
        end
    end
    return h
end

function HashMap:foreach(f, ...)
    for key, value in pairs(self) do
        f(key, value, ...)
    end
    return self
end

function HashMap:has(key)
    return self[key] ~= nil
end

function HashMap:remove(key)
    local data = self[key]
    self[key] = nil
    return data
end

return HashMap
