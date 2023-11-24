--- Useful functions related to creating, modifying and exhausting iterators.
--
-- This module is divided into 3 sub-tables.
--
-- **Source functions**
--
-- These create an iterator, and represent a few things that are tktk
--
-- **Sink functions**
--
-- These functions all exhaust an iterator in some way. Collect is the most
-- obvious, just dropping your values into a table. I'm sure it's code that's
-- been written tens of thousands of times, but tktk
--
-- Some of these functions are
--
-- **Transforming functions (Magic!)**
--
-- The bulk of this module is focused on the Magic table, which contains
-- functions which transform iterators. All of these functions are as lazy as
-- possible.
--
-- There are two ways to use these functions. The first is as regular
-- functions, so you can do something like this: `magic.map(s:gmatch('patt'),
-- myfunc)`. However, with longer chains of transformations, this gets unwieldy
-- and difficult to read, as you have to do so from the inside out.
--
-- Therefore, another mode of interaction is offered. You can enchant (haha)
-- your iterator to give it the methods in this table as extension methods,
-- like so:
--
-- ```
-- local it = str:gmatch(patt)
--
-- local raw_data = magic(it):map(myfunc):skip(2):filter(mypred)
-- -- note that because these are lazy, the iterator has not yet been advanced!
-- local data = raw_data:collect()
-- ```
--
-- This is inspired by Rust and Ruby, both of which have similar syntax.
--
-- There are two ways to transform a normal iterator into one of these
-- constructs. The first is to use any of them with the normal function call
-- syntax. This will set the metatables such that further transformations can
-- be made in the object-oriented way. Example: `iterx.magic.map(iter,
-- myfunc):take(3)`.
--
-- The second way is to call the table itself as a function. This will wrap the
-- iterator in a function which does not transform it at all, but enables the
-- object-oriented interface. Example: `local myiter = iterx.magic(iter);
-- myiter:map(myfunc):take(3)`.
--
-- @module iterx


local tinsert, concat = table.insert, table.concat
local BRACES = { '[', ']' }

local function strip_table_address(obj)
    local obj_type = type(obj)
    if obj_type == 'table' then
        -- parens make sure the second return value of gsub is ignored
        -- tragically, this makes this NOT a proper tail call :sob:
        return (string.gsub(tostring(obj), [[: 0x%x+$]], '', 1))
    else
        return tostring(obj)
    end
end

local function iterx_tostring(name, inner, second)
    local stringbuilder = {name, BRACES[1], strip_table_address(inner)}
    if second then
        tinsert(stringbuilder, ', ')
        tinsert(stringbuilder, strip_table_address(second))
    end
    tinsert(stringbuilder, BRACES[2])
    return concat(stringbuilder)
end

local iterx

iterx = {
    magic = {

        --- Chain together two iterators, one after the other.
        -- After the first time the first iterator returns nil, values from the
        -- second iterator will be returned.
        -- @function magic.chain
        -- @param iter the first iterator to chain
        -- @param other the second iterator to chain
        -- @return an iterator combining the two source iterators
        chain = function(iter, other)
            local first_returned_nil = false
            return setmetatable({}, {
                __call = function()
                    if first_returned_nil then
                        return other()
                    end
                    local val = iter()
                    if val == nil then
                        first_returned_nil = true
                        return other()
                    else
                        return val
                    end
                end,
                __index = iterx.magic,
                __tostring = function()
                    return iterx_tostring('Chain', iter, other)
                end,
            })
        end,

        --- Collect elements into a table
        -- This is identical to `sink.collect`, it is only included in this
        -- table so that it can be found in the index chain for the magic
        -- objects.
        -- @function magic.collect
        -- @param iter the iterator to collect
        -- @return an array-like table with the elements returned from the
        -- wrapped iterator
        collect = function(iter) return iterx.sink.collect(iter) end,

        --- Transform an iterator, emitting elements that have ben altered by a function.
        -- The classic map function to transform a series of something into a series of something else.
        -- @function magic.map
        -- @param iter the iterator to wrap and transform
        -- @param f the function to call on each member of the iterator
        -- @return a lazy Map iterator
        map = function(iter, f)
            return setmetatable({}, {
                __call = function()
                    local val = iter()
                    if val then
                        return f(val)
                    end
                end,
                __index = iterx.magic,
                __tostring = function()
                    return iterx_tostring('Map', iter, f)
                end,
            })
        end,

        --- Skip a number of elements from the beginning of an iterator.
        -- All skipping is done at the first call to this iterator.
        -- @function magic.skip
        -- @param iter the iterator to skip elements of
        -- @param[number] the number of elements to skip
        -- @return an iterator which will skip n elements, then return elements from the wrapped iterator
        skip = function(iter, n)
            local count = 0
            return setmetatable({}, {
                __call = function()
                    while count < n do
                        count = count + 1
                        iter()
                    end
                    return iter()
                end,
                __index = iterx.magic,
                __tostring = function()
                    return iterx_tostring('Skip', iter, n)
                end,
            })
        end,

        --- Skip elements until a predicate returns false.
        -- For each element, call a predicate function with it as the argument. If that
        -- function returns truthy, try again on the next element. When that function
        -- returns false, return elements from the iterator until it is exhausted. (At
        -- this point, the predicate will no longer be tested at all.)
        --
        -- All skipping will be done on the first call to this iterator.
        -- @function magic.skip
        -- @param iter the iterator to wrap
        -- @param f the function to use as a test
        -- @return a lazy SkipWhile iterator
        skipwhile = function(iter, f)
            -- skips until the first false
            local done_skipping = false
            return setmetatable({}, {
                __call = function()
                    if done_skipping then
                        return iter()
                    end
                    local val = iter()
                    if val == nil then
                        return nil
                    end
                    while f(val) do
                        val = iter()
                    end
                    done_skipping = true
                    return val
                end,
                __index = iterx.magic,
                __tostring = function()
                    return iterx_tostring('SkipWhile', iter, f)
                end,
            })
        end,

        --- Take elements while a predicate returns true
        -- tktktk
        takewhile = function(iter, f)
            local done_returning = false
            return setmetatable({}, {
                    __call = function ()
                        if done_returning then
                            return nil
                        else
                            local val = iter()
                            if f(val) then
                                return val
                            else
                                done_returning = true
                                return nil
                            end
                        end
                    end,
                    __index = iterx.magic,
                    __tostring = function ()
                        return iterx_tostring('TakeWhile', iter, f)
                    end,
                })
        end,

        --- Use only the first few elements of an iterator.
        -- This iterator may emit fewer than `n` elements, but never more.
        -- @function magic.take
        -- @param[type=func] iter iterator to take from
        -- @param[type=number] n the number of elements to take
        -- @return an iterator that will emit at most `n` elements from the wrapped
        -- iterator
        take = function(iter, n)
            local count = 0
            return setmetatable({}, {
                __call = function()
                    count = count + 1
                    if count > n then
                        return nil
                    else
                        return iter()
                    end
                end,
                __index = iterx.magic,
                __tostring = function()
                    return iterx_tostring('Take', iter, n)
                end,
            })
        end,

        --- Zip together two iterators.
        -- Iterates over two iterators, returning a value from both. Is
        -- exhausted when either component is exhausted.
        -- @function magic.zip
        -- @param iter the first iterable to zipped
        -- @param other the second iterable to be zipped
        -- @return a lazy Zip iterator, which will return paired values from
        -- each of the source iterators until one returns nil
        zip = function(iter, other)
            return setmetatable({}, {
                __call = function()
                    local a = iter()
                    local b = other()
                    if a == nil or b == nil then
                        return nil, nil
                    else
                        return a, b
                    end
                end,
                __index = iterx.magic,
                __tostring = function()
                    return iterx_tostring('Zip', iter, other)
                end,
            })
        end,


--- Force an iterator to always return nil after the first time it does so.
-- Lua iterators in general may resume returning values after returning nil, so
-- this function circumvents that.
terminate = function (iter)
    local has_returned_nil = false
    return setmetatable({}, {
        __call = function()
            if has_returned_nil then
                return nil
            end
            local val = iter()
            if val == nil then
                has_returned_nil = true
                return nil
            else
                return val
            end
        end,
        __index = iterx.magic,
        __tostring = function() return iterx_tostring('Terminate', iter) end,
    })
end,

    },

    --- Table of operators as functions.
    -- This is mostly intended for use in `reduce` but may be useful in other
    -- contexts.
    -- @table operators
    operators = {
        --- +
        -- @function operators.add
        add = function (first, second) return first + second end,
    },

    sink = {

        --- Collect an iterator into a table.
        -- @function sink.collect
        -- @param iter the iterator to collect
        -- @return a table with all values from the now-exhausted iterator.
        collect = function(iter)
            local t = {}
            for thing in iter do
                tinsert(t, thing)
            end
            return t
        end,

        --- Reduce an iterator to one value by repeatedly applying a binary function.
        -- @function sink.reduce
        -- @param iter the iterator to reduce
        -- @param f the function to apply to successive pairs. Should take
        -- 2 arguments and return one.
        -- @param[opt=nil] initial initial value to seed the reduction
        -- function with. If not provided, then the first value of the
        -- iterator will be provided.
        reduce = function(iter, f, initial)
            if f == nil then
                return nil, 'No reduction function provided!'
            end
            local value
            if initial == nil then
                value = iter()
            else
                value = initial
            end
            for element in iter do
                value = f(value, element)
            end
            return value
        end,
    },

    source = {

        --- Turn any lua object into an iterator.
        -- If the object is a string, then an iterator over its characters is
        -- returned.
        -- If the object is a table, then pairs() is returned.
        -- Any other object is returned as a single-emission iterator, as `single_iterable`.
        -- @function source.always_iterable
        -- @param obj the object to iterate over
        -- @return something guaranteed to be iterable.
        -- @see source.single_iterable
        always_iterable = function(obj)
            local obj_type = type(obj)
            if obj_type == 'table' then
                return pairs(obj)
            elseif obj_type == 'string' then
                return string.gsub(obj, '.')
            else
                local emitted = false
                return function()
                    if not emitted then
                        emitted = true
                        return obj
                    else
                        return nil
                    end
                end
            end
        end,

        --- Count up indefinitely.
        -- This functions returns an iterator which will start from the given
        -- number, and increment by the given step (which defaults to 1).
        -- @function source.count
        -- @param[type=number,opt=1] start the number to start counting at
        -- @param[type=number,opt=1] step the size of the step to increment by
        count = function(start, step)
            local current = start or 0
            local stepsize = step or 1
            return function()
                current = current + stepsize
                return current
            end
        end,

        --- Repeat a cycle of objects endlessly.
        -- When passed an array-like table, will emit elements from that table,
        -- in order, repeating from the beginning when the end of the table is
        -- reached. The hash-like part of the table, if there is any, is
        -- ignored. Passing in a non-table or a table with no array-like
        -- section (techically, if `table[1] == nil`) will result in an error.
        -- Because all tables are references, be wary of changing the array you
        -- pass in via another reference. Behavior if this happens may be
        -- unpredictible.
        -- @function source.cycle
        -- @param[type=tab] array the array to repeat
        -- @return an iterator which will emit elements of the array
        -- in an endless cycle
        cycle = function(array)
            if type(array) ~= 'table' then
                return nil, 'Must be a table!'
            end
            if array[1] == nil then
                return nil, 'Table must have a value at position 1!'
            end
            local max = #array
            local idx = 0
            return function()
                if idx >= max then
                    idx = 0
                end
                idx = idx + 1
                return array[idx]
            end
        end,

        --- Iterate over a range.
        -- This iterator moves from start to stop with increments of step.
        -- @function source.range
        -- @param[type=number] start where to start counting from
        -- @param[type=number] stop where to stop iterating at
        -- @param[type=number,opt=1] what step size to use
        -- @return an iterator that will iterate over the supplied range
        range = function(start, stop, step)
            if start == nil or stop == nil then
                return nil, 'Must provide both start and stop values!'
            end
            local mystep = step or 1
            local current = start - mystep
            return setmetatable({}, {__call = function()
                current = current + mystep
                if current > stop then
                    return nil
                end
                return current
            end,
            __index = iterx.magic,
            __tostring = function () return string.format('Range%s%d, %d, %d%s', BRACES[1], start, stop, step, BRACES[2]) end,
        })
        end,

        --- Repeat a single element endlessly.
        -- Repeat a single supplied element endlessly. This iterator will never
        -- be exhausted.
        -- This function should be called "repeat" but that is a reserved word in lua.
        -- @function source.reiterate
        -- @param element the element that will be repeated
        -- @return an iterator which emits the given element every time it is called
        reiterate = function(element)
            return setmetatable({}, {__call =  function() return element end, 
                    __index = iterx.magic,
                    __tostring = function() return string.format('Reiterate%s%s%s', BRACES[1], element, BRACES[2]) end,
            })
        end,

        --- Emit a given element once as an iterable.
        -- Can transforma a single object into a (length one) iterator. After
        -- this element is emitted, this iterator will always emit nil.
        -- Note that this closure will retain a reference to the provided
        -- element even after it's been emitted, which may not be expected.
        -- @function source.single_iterable
        -- @param element any lua object, which will be emitted once.
        -- @return the single-emission iterator
        single_iterable = function(element)
            local emitted = false
            return setmetatable({}, {
                    __call = function()
                if not emitted then
                    emitted = true
                    return element
                else
                    return nil
                end
            end,
            __index = iterx.magic.
            __tostring = function () return string.format('SingleIterable%s%s%s', BRACES[1], element, BRACES[2]) end,
        })
        end,

    },
}

setmetatable(iterx.magic, {
    __call = function(_, iter)
        return setmetatable({}, {
            __call = iter,
            __index = iterx.magic,
            __tostring = function()
                return iterx_tostring('Magic', iter)
            end,
        })
    end,
})

--- Filter an iterator, emitting only elements that a predicate is true of.
function iterx.magic.filter(iter, f)
    return setmetatable({}, {
        __call = function()
            local val = iter()
            if val == nil then
                return nil
            end
            while not f(val) do
                val = iter()
                if val == nil then
                    return nil
                end
            end
            return val
        end,
        __index = iterx.magic,
        __tostring = function() return iterx_tostring('Filter', iter, f) end,
    })
end


return iterx
