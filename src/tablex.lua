--- Some useful methods for dealing with tables.
local tinsert = table.insert
local tablex = {}

local type_order = {
    ['nil'] = 1,
    boolean = 2,
    number = 3,
    string = 4,
    ['function'] = 5,
    userdata = 6,
    thread = 7,
    table = 8,
}

--- A compare function that provides an ordering over all types in lua.
-- Suitable for passing to `table.sort`.
-- types: nil, boolean, number, string, function, userdata, thread, table
-- nil: can never be a key in a table, and so is ignored.
-- boolean: `true` comes before `false`
-- number: already ordered
-- string: already ordered
-- function: sorted by address
-- userdata: sorted by address
-- thread: sorted by address
-- table: sorted by successive keys returned by `next()`
-- @function tablex.compare_anything
-- @param a first object to compare
-- @param b second object to compare
-- @return a boolean, true when a comes before b, and false when that does not hold
local function compare_anything(a, b)
    local a_type = type(a)
    local b_type = type(b)
    if a_type == b_type then
        if rawequal(a, b) then
            return false
        elseif a_type == 'boolean' then
            return a
        elseif a_type == 'function' or a_type == 'thread' or a_type ==
            'userdata' then
            return tostring(a) < tostring(b)
        elseif a_type == 'table' then
            return compare_anything(next(a), next(b))
        else
            return a < b
        end
    else
        return type_order[a_type] < type_order[b_type]
    end
end

tablex.compare_anything = compare_anything

--- Sort any table.
-- Uses `table.sort` behind the scenes, so this will sort a table in-place! The
-- comparison function is able to gracefully handle mixed types in a resonable
-- way. Of course, it knows nothing about how you are using data in your
-- program, or your custom types, so it may not b suitable for all cases.
-- A reference to the now-sorted table is returned for convenience.
-- @param t the table to sort
-- @param[type=func,opt] func a sorting function, if you want to override `compare_anything`
-- @return t, which is now sorted
function tablex.sort(t, func)
    local myfunc = func or compare_anything
    table.sort(t, myfunc)
    return t
end

-- TODO: fix possible recursion errors
function tablex.flatten(t, new_tab)
    local my_tab = new_tab or {}
    for i = 1, #t do
        if type(t[i]) ~= 'table' then
            tinsert(my_tab, t[i])
        else
            tablex.flatten(t[i], my_tab)
        end
    end
    return new_tab
end

return tablex
