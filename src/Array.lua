--- A module defining a scalar array or list type, built off of tables, but with many
-- convenience functions built in. It is inspired by, but not identical to the
-- python list type.
--
-- Most functions return a new Array with the transformations applied.
-- Generally, the original Array is not modified.
--
-- It is encouraged for Arrays to be of a homogeneous type, but this
-- is not enforced. It is up to the programmer to use them
-- responsibly.
local tinsert, tremove = table.insert, table.remove
local setmetatable = setmetatable
local type = type

local ArrayMT = {__name = 'Array'}
local Array = {__name = 'Array', __index = ArrayMT}

setmetatable(Array, ArrayMT)

--- Class Methods
-- @section classmethods

--- Create a new Array.
-- @param obj an object. If it is a table, then the array-like portions of the
-- table will be added as the elements of the Array. If it is not a table, then
-- the new Array will have a single element, obj. (e.g. `Array:new(0.3) ==
-- Array{0.3}`). The exception is nil, which will result in the creation of an
-- empty Array.
-- @return new Array object
function Array:new(obj)
    local a = {}
    setmetatable(a, self)
    if obj == nil then
        return a
    end
    if type(obj) ~= 'table' then
        tinsert(a, obj)
        return a
    else
        for i = 1, #obj do
            a:append(obj[i])
        end
        return a
    end
end

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

--- Initialize an array
-- Helper function which combines `Array.range` and `Array:map` to prefill an
-- array wih calculated values.
-- @param[type=number] n the size of the array, behaves identical to single-argument form of `Array.range`
-- @param[type=func] f the function to call for each element of the array. Will be passed
-- the index of the element it is operating on, and additional arguments may be
-- passed to initialize which will be forwarede on to f.
-- @return the newly created and filled Array
-- @see Array.range
-- @see Array:map
function Array.initialize(n, f, ...)
    return Array.range(n):map(f, ...)
end

--- Metatable Events
-- @section metatableevents

ArrayMT.__call = Array.new

--- Check if Arrays are equal.
-- An Array is equal to another Array if they are the same length and each
-- element of them compares the same.
function Array:__eq(other)
    if #self ~= #other then
        return false
    end
    for i = 1, #self do
        if self[i] ~= other[i] then
            return false
        end
    end
    return true
end

function Array:__tostring()
    local string_builder = {}
    local len = #self
    tinsert(string_builder, 'Array {')
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
end

--- Allows for Arrays to be added to objects (and objects to be added to
-- arrays). Lua kindly presents arguemnts in left-to-right order, so results
-- should be as expected.
-- Adding a table to an Array or vice versa results in a new Array with the
-- elements from each antecedent. (e.g. `{1, 2} + Array{3, 4} == Array{1, 2}
-- + {3, 4} == Array{1, 2, 3, 4}`).
-- Adding another type of object to an Array results in a new Array with that
-- object at the front or back of the extant Array. (e.g. `Array{'@'} + '&' ==
-- '@' + Array{'&'} == Array{'@', '&'}`)
-- @param first the first object or Array
-- @param second the second object or Array
function Array.__add(first, second)
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
end

--- Instance Methods
-- @section instancemethods

--- Add on object to the end of an array.
-- N.B. This is one of the few functions that returns the same Array. Be wary
-- of modifications if you are retaining references.
-- @param obj Object to add to the end of the array.
-- @return the same Array, with the new object appended.
function ArrayMT:append(obj)
    tinsert(self, obj)
    return self
end

--- Run a function for each member of an Array.
-- If your function has side effects, this is preferred over Array:map()
-- @param[func] f Function to run for each member of the Array. The first
-- argument passed to the function will be the value of the array. Further
-- arguments passed to foreach will be passed on to f.
-- @return the same Array, unaltered (unless f has somehow altered it.)
-- Behavior if you try to modify an Array while iterating over it is undefined.
-- @see Array:map
function Array:foreach(f, ...)
    for i = 1, #self do
        f(self[i], ...)
    end
    return self
end

--- Map a function to each value of an array.
-- This is not useful for operating on the indices of the values in the array,
-- for that look at `range`. (e.g. `Array.range(n):map(f, ...)`).
-- @param[type=func] f function to apply to each member of the array. The first value
-- provided to the function will be the value of the array item, and further
-- parameters passed to map will be pass along to the function.
-- @return a new Array with the calculated values.
-- @see Array.range
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
function ArrayMT:filter(f, ...)
    local a = Array:new()
    local f = f or function(_)
        return true
    end
    for i = 1, #self do
        if f(self[i], ...) then
            tinsert(a, self[i])
        end
    end
    return a
end

--- Add a table of items to the end of an Array.
-- Uses `__add` to append the given item to the end of the table. If it is
-- a table, then it will add each item to the Array. If it is any other object,
-- then that object will be added to the end of the Array. To add a table as an
-- array item, use `append`.
-- @param item the table or object to add to the end of the Array.
-- @return the extended Array.
-- @see Array:__add
function ArrayMT:extend(item)
    return self + item
end

function ArrayMT:len()
    return #self
end

function Array:copy()
    local new = Array()
    for i = 1, #self do
        tinsert(new, self[i])
    end
    return new
end

--- Pop the last item off of an Array.
-- @return the item
-- @return the modified Array
function ArrayMT:pop()
    if #self == 0 then
        return nil, 'Array is of length 0'
    end
    local item = tremove(self)
    return item, Array
end

--- Remove and return the item from a specific index in an Array.
-- @param[type=number] index the index of the item to remove
-- @return the remnoved item
-- @return the modified Array
function ArrayMT:remove(index)
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
