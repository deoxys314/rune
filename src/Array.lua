--- A scalar list.
--
-- This class is heavily inspired by the Python list type.
--
-- Most functions return a new Array with the transformations applied. This may
-- be useful for chaining operations. Generally, the original Array is not
-- modified.
--
-- It is encouraged for Arrays to be of a homogeneous type, but this
-- is not enforced. It is up to the programmer to use them
-- responsibly.
--
-- @classmod Array
local tinsert, tremove = table.insert, table.remove
local setmetatable = setmetatable
local type = type

local Array = {}
local InstanceMetatable = {
    __index = Array,
    __name = 'Array',

    --- Convert an Array to a string representation.
    -- @return a string representing the Array.
    __tostring = function(self)
        local string_builder = {'Array {'}
        local len = #self
        for i = 1, len do
            if type(self[i]) == 'string' then
                tinsert(string_builder, '"' .. self[i] .. '"')
            else
                tinsert(string_builder, tostring(self[i]))
            end
            if i ~= len then
                tinsert(string_builder, ', ')
            end
        end
        tinsert(string_builder, '}')
        return table.concat(string_builder)
    end,

    --- Allows for Arrays to be added to objects (and objects to be added to
    -- Arrays). Lua kindly presents arguemnts in left-to-right order, so results
    -- should be as expected.
    -- Adding a table to an Array or vice versa results in a new Array with the
    -- elements from each antecedent. (e.g. `{1, 2} + Array{3, 4} == Array{1, 2}
    -- + {3, 4} == Array{1, 2, 3, 4}`).
    -- Adding another type of object to an Array results in a new Array with that
    -- object at the front or back of the extant Array. (e.g. `Array{'@'} + '&' ==
    -- '@' + Array{'&'} == Array{'@', '&'}`)
    -- @param first the first object or Array
    -- @param second the second object or Array
    -- @return a new Array with the summed elements
    __add = function(first, second)
        local new = Array()
        if type(first) == 'table' then
            for i = 1, #first do
                tinsert(new, first[i])
            end
        else
            tinsert(new, first)
        end
        if type(second) == 'table' then
            for i = 1, #second do
                tinsert(new, second[i])
            end
        else
            tinsert(new, second)
        end
        return new
    end,

    --- Check if Arrays are equal.
    -- An Array is equal to another Array if they are the same length and each
    -- element of them compares the same.
    __eq = function(self, other)
        if #self ~= #other then
            return false
        end
        for i = 1, #self do
            if self[i] ~= other[i] then
                return false
            end
        end
        return true
    end,
}

--- Create a new Array.
-- @param obj an object. If it is a table, then the array-like portions of the
-- table will be added as the elements of the Array. If it is not a table, then
-- the new Array will have a single element, obj. (e.g. `Array:new(0.3) ==
-- Array{0.3}`). The exception is `nil`, which will result in the creation of
-- an empty Array.
-- @return new Array object
function Array.new(_, obj)
    local a = {}
    setmetatable(a, InstanceMetatable)
    if type(obj) == 'table' then
        for i = 1, #obj do
            a:append(obj[i])
        end
    else
        tinsert(a, obj)
    end
    return a
end

local ClassMetatable = {__call = Array.new}

setmetatable(Array, ClassMetatable)

--- Create a range of numeric values.
-- If only `n` is provided, then a range from 1 to `n` is created.
-- If `n` and `m` are provided, then a range from `n` to `m` is created.
-- Only integers are accepted. Other types will have undefined behavior.
-- @param[type=number] n
-- @param[type=number,opt] m
-- @return a new Array with the desired range of integers.
function Array.range(n, m)
    local a = Array()
    if type(n) ~= 'number' then
        return a
    end
    if m == nil then
        for i = 1, n do
            tinsert(a, i)
        end
    else
        for i = n, m do
            tinsert(a, i)
        end
    end
    return a
end

--- Create an Array from an iterator.
-- This method will create a new Array with all elements from the provided
-- iterator. Note that this is eagerly evaluated.
-- @param[type=func] iter the iterator to turn into the Array
-- @return the newly-created Array
function Array.from_iterator(iter)
    local t = {}
    setmetatable(t, InstanceMetatable)
    for thing in iter do
        tinsert(t, thing)
    end
    return t
end

--- Create an array and initialize it based on a function.
-- Creates a new Array and sets the values to the results of a function. This
-- function is provided the index it is generating a value for.
-- @param[type=numer] size the size of the newly created Array
-- @param[type=func] func function to create the value with
function Array.initialize(size, func)
    local a = Array()
    local func = func or function (n) return n end
    for idx = 1, size do
        tinsert(a, func(idx))
    end
    return a
end

--- Add on object to the end of an Array.
-- N.B. This is one of the few functions that returns the same Array. Be wary
-- of modifications if you are retaining references.
-- @param obj Object to add to the end of the Array.
-- @return the same Array, with the new object appended.
function Array:append(obj)
    tinsert(self, obj)
    return self
end

--- Run a function for each member of an Array.
-- If your function has side effects, this is preferred over Array:map()
-- @param[func] f Function to run for each member of the Array. The first
-- argument passed to the function will be the member of the Array.
-- @param[opt] ... additional arguments to pass to `f`
-- @return the same Array, unaltered (unless f has somehow altered it.)
-- Behavior if you try to modify an Array while iterating over it is undefined.
-- @see Array:map
function Array:foreach(f, ...)
    for i = 1, #self do
        f(self[i], ...)
    end
    return self
end

--- Map a function to each value of an Array.
-- This is not useful for operating on the indices of the values in the Array,
-- for that use ipairs (`for idx, value in ipairs(myArray) do ... end`).
--
-- Note that this is eagerly evaluated.
-- @usage assert(Array.range(3):map(function (x) return x * 2 end) == Array{2, 4, 6})
-- @param[type=func] f function to apply to each member of the Array. The first value
-- provided to the function will be the value of the Array item, and further
-- parameters passed to map will be pass along to the function.
-- @return a new Array with the calculated values.
function Array:map(f, ...)
    local a = Array()
    for i = 1, #self do
        tinsert(a, f(self[i], ...))
    end
    return a
end

--- Filter an Array to values that pass a test.
-- @param[type=func, opt] f function to apply to each member of the Array. If
-- the return value is falsey, then the value will not be included in the
-- returned Array.
-- @return a new `Array` with the filtered values.
function Array:filter(f, ...)
    local a = Array:new()
    local func = f or function(_) return true end
    for i = 1, #self do
        if func(self[i], ...) then
            tinsert(a, self[i])
        end
    end
    return a
end

--- Map and filter an Array.
-- @param[type=func] f function to aply to each member of the Array. If it
-- returns nil, then the value is dropped. Any other result is appended to the
-- returned Array.
-- @return a new Array with the filtered and transformed values.
function Array:filtermap(f, ...)
    local a = Array:new()
    local func = f or function(x) return x end
    for i = 1, #self do
        local result = func(self[i], ...)
        if result ~= nil then
            tinsert(a, result)
        end
    end
    return a
end

--- Add a table of items to the end of an Array.
-- Uses `__add` to append the given item to the end of the table. If it is
-- a table, then it will add each item to the Array. If it is any other object,
-- then that object will be added to the end of the Array. To add a table as an
-- Array item, use `append`.
-- @param item the table or object to add to the end of the Array.
-- @return the extended Array.
-- @see Array:__add
function Array:extend(item) return self + item end

--- Get the number of elements in an Array.
-- Because under the hood, Arrays are just normal Lua tables, this is based off
-- of Lua's built-in `#`. As such, it has similar pitfalls. If you are using
-- the built-in interfaces to Array, this should not cause issues. If you have
-- directly been inserting or removing elements, you may get unexpected
-- results. See section 3.4.7 of the lua manual for more information.
-- @return an integer representing the number of elements in the Array
function Array:len() return #self end

--- Copy an Array.
-- Creates a new Array, which is a copy of the first one. Note that this is
-- a very simple opration: references will be pointing to the same object in
-- both Arrays.
-- @return a new Array which is a copy of this Array
function Array:copy()
    local new = Array()
    for i = 1, #self do
        tinsert(new, self[i])
    end
    return new
end

--- Pop the last item off of an Array.
-- Removes the last item in the Array and returns it, and the Array. If the
-- Array is length 0, then nil and an error message are returned.
-- @return the item
-- @return the modified Array
function Array:pop()
    if #self == 0 then
        return nil, 'Array is of length 0'
    end
    local item = tremove(self)
    return item, Array
end

--- Remove and return the item from a specific index in an Array.
-- Because this has to shift down elements above the removed item, it can be
-- slow in some cases.
--
-- If the index provided is not suitable, `nil` and an error message will be
-- returned.
-- @param[type=number] index the index of the item to remove
-- @return the remnoved item
-- @return the modified Array
function Array:remove(index)
    if type(index) ~= 'number' then
        return nil, 'Given index is not a number'
    end
    if #self == 0 then
        return nil, 'Array is of length 0'
    end
    if index > #self then
        return nil, 'Index is larger than length of Array'
    end
    local item = tremove(self, index)
    return item, Array
end

return Array
