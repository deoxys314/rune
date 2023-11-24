#!/usr/bin/env lua

-- calling this without color makes life simpler for trying to display and/or
-- parse the output in weird environments.
local lust = require('test.lust.lust')

local describe = lust.describe
local expect = lust.expect
local it = lust.it

local rune = require 'rune'

lust.paths.raw_eq = {
    test = function(first, second)
        local result = rawequal(first, second)
        local first_str, second_str = tostring(first), tostring(second)
        return result, 'exepcted rawequal(' .. first_str .. ', ' .. second_str .. ') to be true',
               'expected rawequal(' .. first_str .. ', ' .. second_str .. ') to be false'
    end,
}
table.insert(lust.paths.to, 'raw_eq')
table.insert(lust.paths.to_not, 'raw_eq')

describe('Test Utilities', function()

    describe('Array', function()
        local Array = rune.Array
        describe('metamethods', function()
            it('__call', function()
                -- we can call this
                expect(Array).to_not.fail()
                -- we can call it with a table argument
                expect(function() Array { 15, 23 } end).to_not.fail()
                -- we can call it with other types
                expect(function() Array { 'hi', 'mom!' } end).to_not.fail()
                -- we can call with mixed type
                expect(function() Array { 'string!', 2, function() end, {}, 0.3 } end).to_not
                    .fail()
            end)

            it('__eq', function()
                -- Arrays with the same things are equal
                expect(Array()).to.equal(Array())
                expect(Array { 1, 2, 3 }).to.equal(Array { 1, 2, 3 })

                do
                    local t = { 15, 30, 45 }
                    -- Arrays which have the same contents should be equal
                    expect(Array(t)).to.equal(Array(t))
                end

                -- Arrays with different things are unequal
                expect(Array { 1 }).to_not.be(Array { 2 })
                -- Arrays with different lengths are unequal
                expect(Array { true, true }).to_not.be(Array { true })
                -- if we use hash keys, then we ignore them
                expect(Array { 1, 2, 3, red = 0, blue = 0, green = 0 }).to.equal(Array { 1, 2, 3 })
            end)

            it('__name', function()
                -- I have set the name correctly
                expect(getmetatable(Array()).__name).to.equal('Array')
            end)

            it('__tostring', function()
                -- empty arrays render properly
                expect(tostring(Array())).to.equal('Array {}')
                -- fuller arrays render properly
                expect(tostring(Array { 1, 2 })).to.equal('Array {1, 2}')
                -- strings render properly
                expect(tostring(Array { '@', 3, 4, '2' })).to.equal('Array {"@", 3, 4, "2"}')
            end)

            it('__add', function()
                -- add an array to an array
                expect(Array { 'A', 'B' } + Array { 'C', 'D' }).to.be(Array { 'A', 'B', 'C', 'D' })
                -- add a table to an array
                expect(Array { 1, 2 } + { 3, 4 }).to.equal(Array { 1, 2, 3, 4 })
                -- add an array to a table
                expect({ 1, 2 } + Array { 3, 4 }).to.equal(Array { 1, 2, 3, 4 })
                -- add a random object to an array
                expect(Array { '$', '#' } + '%').to.equal(Array { '$', '#', '%' })
                -- add an array to a random object
                expect(0.15 + Array { 0.255, 0.23 }).to.equal(Array { 0.15, 0.255, 0.23 })
            end)
        end)

        describe('methods', function()
            it('append', function()
                expect(Array { 2 }:append('2')).to.equal(Array { 2, '2' })
                expect(Array():append(1):len()).to.equal(1)
                expect(Array { '3' }:append('4')).to.equal(Array { '3', '4' })
            end)
            it('copy', function()
                do
                    local a = Array { '$', '%', '()' }
                    expect(function() return a:copy() end).to_not.fail()
                    expect(a:copy()).to.be(a)
                end
            end)
            it('filter', function()
                expect(Array.range(100):filter(function(n) return (n % 3) == 0 end):len()).to
                    .equal(33)
            end)
            it('filtermap', function()
                do
                    local a = Array.range(100):filtermap(function(n)
                        if (n % 2) == 0 then
                            return nil
                        else
                            return false
                        end
                    end)
                    expect(a:len()).to.be(50)
                end
            end)
            it('foreach', function()
                expect(function()
                    Array { true, false, true }:foreach(function(v) return not v end)
                end).to_not.fail()
                do
                    local a = Array { 1, 3, 5, 7 }
                    expect(a:foreach(function(v) return v + 1 end)).to.be(a)
                end
            end)
            it('from_iterator', function()
                local s = 'abcdef'
                expect(Array.from_iterator(string.gmatch(s, '.'))).to.be(Array {
                    'a',
                    'b',
                    'c',
                    'd',
                    'e',
                    'f',
                })
            end)
            it('initialize', function()
                expect(Array.initialize(3, function(x) return x * x end)).to.equal(
                    Array { 1, 4, 9 })
                expect(Array.initialize(5)).to.equal(Array { 1, 2, 3, 4, 5 })
            end)
            it('len', function()
                expect(Array():len()).to.equal(0)
                expect(Array({ 0, 0, 0 }):len()).to.equal(3)
                do
                    local a = Array { true, false, true }
                    expect(a:len()).to.be(#a)
                end
            end)
            it('map', function()
                expect(Array.range(3):map(function(x) return '$' .. x end)).to.equal(Array {
                    '$1',
                    '$2',
                    '$3',
                })
                do
                    local const = '@'
                    expect(Array.range(4):map(function(n) return const .. n end)).to.be(Array {
                        '@1',
                        '@2',
                        '@3',
                        '@4',
                    })
                end
            end)
            it('pop', function()
                expect(Array { 1, 2 }:pop()).to.equal(2)
                expect(Array():pop()).to.fail()
            end)
            it('range', function()
                expect(Array.range(3)).to.equal(Array { 1, 2, 3 })
                expect(Array.range(10, 15)).to.be(Array { 10, 11, 12, 13, 14, 15 })
                expect(Array.range(10, -14)).to.be(Array())
                expect(Array.range(-3)).to.be(Array())
                expect(Array.range('$')).to.be(Array())
            end)
            it('remove', function()
                expect(Array { 1, 2, 3 }:remove(2)).to.equal(2)
                expect(Array({ 1 }):remove(10)).to.fail()
                expect(Array():remove('string')).to.fail()
                expect(Array():remove(1)).to.fail()
            end)
        end)
    end)

    describe('HashMap', function()
        local HashMap = rune.HashMap

        describe('metamethods', function()
            it('__call', function()
                expect(HashMap).to_not.fail()
                expect(function() HashMap { a = 1, b = 2 } end).to_not.fail()
                -- we can combine array-like and hash-like elements
                expect(function() HashMap { '@', '%', a = '^', b = '&' } end).to_not.fail()
            end)
            it('__eq', function()
                expect(HashMap()).to.be(HashMap())
                expect(HashMap()).to_not.be(HashMap { a = 2, b = 3 })
                expect(HashMap { a = 2, b = 3 }).to_not.be(HashMap())
                expect(HashMap { z = 26 }).to_not.be(HashMap { a = 1 })
                expect(HashMap { a = 1 }).to_not.be(HashMap { a = 2 })
            end)
            it('__tostring', function()
                expect(tostring(HashMap())).to.be('HashMap {}')
                expect(tostring(HashMap { x = 34, y = 15 })).to.match(
                    [[^HashMap {[xy]=%d%d, [xy]=%d%d}$]])
            end)
            it('__name', function()
                expect(getmetatable(HashMap())['__name']).to.be('HashMap')
            end)

            it('__add', function()
                -- you can only add tables to hashmaps
                expect(HashMap() + '5').to.be(HashMap())
                -- add table to hashmap
                expect(HashMap { a = 1 } + { b = 2 }).to.be(HashMap { a = 1, b = 2 })
                -- add hashmap to table
                expect({ c = 3 } + HashMap { d = 4 }).to.be(HashMap { d = 4, c = 3 })
                -- add hashmap to hashmap
                expect(HashMap { f = 15 } + HashMap { g = 15 }).to.be(HashMap { g = 15, f = 15 })
            end)
        end)

        describe('methods', function()
            it('add', function()
                expect(HashMap():add('r', 15)).to.be(HashMap { r = 15 })
                expect(HashMap { a = 3 }:add('b', 5)).to.be(HashMap { a = 3, b = 5 })
            end)
            it('update', function()
                expect(HashMap():update({ a = 1, b = 2 })).to.be(HashMap { a = 1, b = 2 })
            end)

            it('initialize', function()
                expect(HashMap.initialize(3, function(n) return n, n * n end)).to.be(
                    HashMap { 1, 4, 9 })
            end)

            it('map', function()
                expect(HashMap { a = 1, b = 2, c = 3 }:map(function(k, _)
                    return tostring(k):upper()
                end)).to.be(HashMap { a = 'A', b = 'B', c = 'C' })
            end)

            it('filter', function()
                expect(HashMap { a = 1, b = 2, c = 3, d = 4 }:filter(function(_, v)
                    return v % 2 == 0
                end)).to.be(HashMap { b = 2, d = 4 })
            end)

            it('foreach', function()
                do
                    local map = HashMap { a = 3, b = 6, c = 9 }
                    expect(function()
                        map:foreach(function(k, v)
                            return string.format('%s -> %s', k, v)
                        end)
                    end).to_not.fail()
                    expect(map).to.be(HashMap { c = 9, b = 6, a = 3 })
                end
            end)

            it('has', function()
                expect(HashMap():has(true)).to_not.be.truthy()
                expect(HashMap { a = 1, b = 2, c = 3 }:has('b')).to.be.truthy()
            end)

            it('remove', function()
                do
                    local map = HashMap { a = 1, b = 2 }
                    local data = map:remove('a')
                    expect(data == 1).to.be.truthy()
                    expect(map).to.be(HashMap { b = 2 })
                end
            end)
        end)
    end)

    describe('Set', function()
        local Set = rune.Set

        describe('metamethods', function()
            it('__call', function()
                expect(Set).to_not.fail()
                expect(function() Set(0) end).to_not.fail()
                expect(function() Set('#') end).to_not.fail()
                expect(Set(0)).to.be(Set { 0 })
                expect(Set('str')).to.be(Set { 'str' })
            end)
            it('__eq', function()
                expect(Set()).to.be(Set())
                expect(Set { 'a', 'c' }).to.be(Set { 'c', 'a' })
                expect(Set { true, false }).to_not.be(Set { 'a' })
                expect(Set { 'a', 'a', 'a', 'b' }).to.be(Set { 'b', 'a' })
                do
                    local s = Set { '$', '*', '#' }
                    expect(s).to.equal(s)
                    expect(s).to.be(s)
                    expect(Set(s)).to.equal(s)
                    expect(Set(Set(Set(Set(s))))).to.equal(s)
                    expect(s).to_not.raw_eq(Set(s))
                    expect(s).to_not.raw_eq(Set(Set(Set(Set(Set(s))))))

                    -- A Set of Set(s) is not equal to the contained Set(s)
                    expect(s).to_not.raw_eq(Set { s })
                    expect(s).to_not.equal(Set { s })
                    expect(s).to_not.be(Set { s })
                end
                do
                    local a = Set { 1, 2, 3, 4 }
                    local b = Set { 2, 3 }
                    expect(a).to_not.be(b)
                    expect(b).to_not.be(a)
                end
            end)
            it('__add', function()
                expect(Set({ 1, 2 }) + Set({ 2, 3 })).to.be(Set { 1, 2, 3 })
                expect(Set { 5, 10 } + Set { 1, 2, 3, 4 }).to.be(Set { 1, 2, 3, 4, 5, 10 })
            end)
            it('__sub', function()
                expect(Set { 1, 2, 3 } - Set { 2 }).to.be(Set { 1, 3 })
                expect(Set { 1, 2, 3 } - Set { 'a', 'b' }).to.be(Set { 1, 2, 3 })
            end)
            it('__tostring', function()
                expect(tostring(Set { 1, 2 })).to.be('Set {1, 2}')
            end)
            it('__pow', function()
                expect(Set { 1, 3, 5 } ^ Set { 5, 7, 9 }).to.be(Set { 5 })
                expect(Set { 1, 2 } ^ Set { '1', '2' }).to.be(Set {})
                expect(Set { 1, 2, 3 } ^ Set { 2, 3, 4 }).to.be(Set { 2, 3 })
            end)
        end)

        describe('initialization', function()
            it('array_like',
               function() expect(Set { 'a', 'b', 'c' }).to.be(Set { 'c', 'b', 'a' }) end)
            it('hash_like',
               function()
                expect(Set { a = 1, b = 1, c = 1 }).to.be(Set { 'a', 'b', 'c' })
            end)
            it('mixed', function() expect(Set { 'a', b = 3 }).to.be(Set { 'a', 'b' }) end)
            it('negative_keys', function()
                expect(Set { [-1] = true, [-5] = true, [0] = true }).to.be(Set { -1, 0, -5 })
            end)
            it('float_keys', function()
                expect(Set { [0.3] = 'junk', [100.005] = 'junk' }).to.equal(Set { 100.005, 0.3 })
            end)
        end)

        describe('methods', function()
            it('add', function()
                expect(Set():add(0)).to.be(Set { 0 })
                expect(Set { 1, 2 }:add(4)).to.be(Set { 4, 2, 1 })
            end)
            it('contains', function()
                expect(Set { 1, 2, 3 }:contains(2)).to.be.truthy()
                expect(Set { 6, 7, 8 }:contains(2)).to_not.be.truthy()
                do
                    local t = {}
                    expect(Set { 1, 2, t }:contains(t)).to.be.truthy()
                    expect(Set { 1, 2, {} }:contains(t)).to_not.be.truthy()
                end
            end)
            it('difference', function()
                expect(Set():difference(Set { 1, 2, 3 })).to.be(Set())
                expect(Set { 1, 2, 3, 4 }:difference(Set { 1, 2 })).to.be(Set { 3, 4 })
            end)
            it('intersection', function()
                expect(Set { 1, 2, 3 }:intersection(Set { 3, 4, 5 })).to.be(Set { 3 })
                expect(Set { 15, 30, 45 }:intersection(Set { 7, 14, 21 })).to.be(Set {})
                expect(Set { 1, 2, 3 }:intersection(Set { 2, 3, 4 })).to.be(Set { 2, 3 })
            end)
            it('items', function()
                do
                    local s = Set { '@', '^', '*' }
                    local t1 = {}
                    expect(function()
                        for thing in s:items() do
                            table.insert(t1, thing)
                        end
                    end).to_not.fail()
                    expect(#t1).to.equal(3)

                    expect(function()
                        for thing, val in s:items() do
                            if thing then
                                if val ~= true then
                                    return nil
                                end
                            end
                        end
                        return true
                    end).to_not.fail()
                end
            end)
            it('remove', function()
                expect(Set { 1, 2, 3 }:remove(2)).to.be(Set { 1, 3 })
                do
                    local s = Set { 1, 2, 3, 4, 5, 6, 7, 8 }
                    local newset, key = s:remove(4):remove(5)
                    expect(newset).to.be(Set { 1, 2, 3, 6, 7, 8 })
                    expect(key).to.be(5)
                end
            end)
            it('union', function()
                expect(Set { 1, 2 }:union(Set { 1 })).to.be(Set { 1, 2 })
                expect(Set { 1, 2 }:union(Set { 3, 4 })).to.be(Set { 1, 2, 3, 4 })
                expect(Set { 1, 2 }:union(Set { 2, 3 })).to.be(Set { 1, 2, 3 })
            end)
        end)
    end)

    describe('MultiSet', function()
        local MultiSet = rune.MultiSet

        describe('metamethods', function()
            it('__call', function()
                expect(MultiSet).to_not.fail()
                expect(function() MultiSet(nil) end).to_not.fail()
                expect(function() MultiSet { 1, 2, 3, 3, 3 } end).to_not.fail()
                expect(function() MultiSet { a = 2, b = 3 } end).to_not.fail()
                expect(function() MultiSet { '@', '@', '#' } end).to_not.fail()
                expect(function() MultiSet 'Hello World!' end).to_not.fail()
                expect(function() MultiSet(2) end).to_not.fail()
                expect(function() MultiSet { 0.2, 0.3, 0.4 } end).to_not.fail()
            end)
            it('__tostring', function()
                expect(MultiSet '$$$$').to.match('^MultiSet { $=4 }$')
                expect(MultiSet '@@###').to.match('^MultiSet { [#@]=[23], [@#]=[23] }$')
            end)
            it('__eq', function()
                expect(MultiSet { 'a', 'a', 'b' }).to.be(MultiSet { a = 2, b = 1 })
                expect(MultiSet { 'a', 'a', 'b' }).to_not.be(MultiSet { 'b', 'b', 'a' })
            end)
        end)

        describe('methods',
                 function()
            it('test', function() expect(nil).to.equal('Not Implemented') end)
        end)
    end)

    describe('misc', function()
        local misc = rune.misc
        it('is_empty', function()
            expect(misc.is_empty(3)).to_not.exist()
            expect(misc.is_empty({})).to.exist()
            expect(misc.is_empty {}).to.be.truthy()
            expect(misc.is_empty { 1, 2, 3 }).to_not.be.truthy()
            expect(misc.is_empty { [10000000] = 0.1 }).to_not.be.truthy()
        end)
        it('is_integer', function()
            for _, v in ipairs { 'a', 0.3, 1.000001, misc, misc.is_empty } do
                expect(misc.is_integer(v)).to_not.be.truthy()
            end
            for _, v in ipairs { 0, 10000000, -45, 6, 15, 20 * 20 } do
                expect(misc.is_integer(v)).to.be.truthy()
            end
        end)
    end)

    describe('stringx', function()
        local stringx = rune.stringx
        local function collect(iter)
            local t = {}
            for thing in iter do
                table.insert(t, thing)
            end
            return t
        end

        it('split', function()
            expect(collect(stringx.split('testing string'))).to.equal({ 'testing', 'string' })
        end)

        it('lines', function()
            local function splitl(str)
                local l = {}
                for line in stringx.lines(str) do
                    table.insert(l, line)
                end
                return l
            end

            expect(splitl('\n\n\n\n$$')).to_not.fail()
            expect(splitl('red\ngreen\nblue')).to.equal({ 'red', 'green', 'blue' })
            expect(splitl([[ace\n\z
                            king\n\z
                            queen\n\z
                            jack\n\z
                            10\n]])).to.equal({ 'ace', 'king', 'queen', 'jack', '10' })
        end)
        it('trim', function()
            expect(stringx.trim('    # #   ')).to.equal('# #')
            expect(stringx.trim('\t1 2 3\n\n')).to.equal('1 2 3')
            expect(stringx.trim('                                   ')).to.equal('')
            expect(stringx.trim('')).to.equal('')
            expect(stringx.trim('%')).to.equal('%')
        end)
        it('dedent', function() expect(nil).to.equal('Not Implemented') end)
        it('chars', function()
            do
                local s = '1234'
                local t = {}
                for c in stringx.chars(s) do
                    table.insert(t, c)
                end
                expect(t).to.equal({ '1', '2', '3', '4' })
            end

        end)
    end)

    describe('pprint', function()
        local pprint = rune.pprint
        it('empty', function() expect(pprint({})).to.equal('{}') end)
        it('string', function() expect(pprint('red')).to.equal('"red"') end)
        it('wierd strings', function()
            expect(pprint('a\tb')).to.equal([["a\tb"]])
            expect(pprint([[\]])).to.equal([["\"]])
            expect(pprint('"')).to.equal([["""]])
            expect(pprint('\v\t\b')).to.equal([["\v\t\b"]])
        end)
        it('number', function()
            expect(pprint(15)).to.equal('15')
            expect(pprint(0.3)).to.equal('0.3')
        end)
        it('table', function()
            expect(pprint({ 'a', 'b', 'c' })).to
                .equal('{\n  [1] = "a",\n  [2] = "b",\n  [3] = "c",\n}')
        end)
        it('nested_table',
           function() expect(pprint({ {}, {} })).to.equal('{\n  [1] = {},\n  [2] = {},\n}') end)

        it('deeply_nested_table', function()
            local t = { '@', { 15, { 'a', 'b' } }, red = 405, green = 102 }
            -- don't forget to escape the brackets!
            expect(pprint(t, 1)).to.match(
                '{\n %[1%] = "@",\n %[2%] = {\n  %[1%] = 15,\n  %[2%] = {\n    %[1%] = "a",\n    %[2%] = "b",\n  },\n},\n %["%l%l%l*"%] = %d%d%d,\n %["%l%l%l*"%] = %d%d%d,\n}')
        end)

        it('cycle', function()
            do
                local t = {}
                table.insert(t, t)
                expect(pprint(t, 1)).to.be('{\n [1] = ... (cycle),\n}')
            end
            do
                local t = { 1, 2, 3 }
                table.insert(t, { 8, 9, t })
                expect(function() return pprint(t) end).to_not.fail()
            end
        end)
    end)

    describe('tablex', function()
        local tablex = rune.tablex
        it('sort', function()
            local t = { { 3 }, '@', 1, -100, { 2 }, '&' }
            expect(tablex.sort(t)).to.equal({ -100, 1, '&', '@', { 2 }, { 3 } })
        end)

        it('compare_anything', function()
            local t = { '#', { -2 }, '@', 10, 0, { -5 } }
            tablex.sort(t, tablex.compare_anything)
            expect(t).to.equal({ 0, 10, '#', '@', { -2 }, { -5 } })
        end)

    end)

    describe('iterx', function()
        local iterx = rune.iterx
        local alphabet = 'abcdefghijklmnopqrstuvwxyz'
        describe('sources', function()
            it('range', function()
                local fives = {}
                for value in iterx.source.range(5, 50, 10) do
                    table.insert(fives, value)
                end
                expect(fives).to.equal({ 5, 15, 25, 35, 45 })
                expect(iterx.source.range(3, 20, 3):collect()).to.equal({ 3, 6, 9, 12, 15, 18 })
            end)
            it('reiterate', function()
                local repetition = iterx.source.reiterate(5)
                for i = 1, 100 do
                    _ = repetition()
                end
                expect(repetition()).to.equal(5)
                expect(repetition:take(5):collect()).to.equal({ 5, 5, 5, 5, 5 })
            end)
        end)

        describe('transformations', function()
            it('take', function()
                local iter = iterx.magic.take(string.gmatch(alphabet, '.'), 5)
                expect(iterx.sink.collect(iter)).to.equal({ 'a', 'b', 'c', 'd', 'e' })
            end)
        end)

        describe('sinks', function()
            it('collect', function()
                local iter = string.gmatch('12345678', '.')
                expect(iterx.sink.collect(iter)).to.equal(
                    { '1', '2', '3', '4', '5', '6', '7', '8' })
            end)
        end)

        describe('combinations', function()
            it('heavy chain', function()
                local iter = string.gmatch(alphabet, '.')
                local vals = iterx.magic(iter):map(function(s)
                    return s:upper():byte()
                end):filter(function(n)
                    for i = 2, n ^ (1 / 2) do
                        if (n % i) == 0 then
                            return false
                        end
                    end
                    return true
                end):map(function(n) return string.char(n) end):skip(5):map(function(s)
                    return s:lower()
                end)
                local vals_string = tostring(vals)
                expect(vals:collect()).to.equal({ 'y' })
            end)
        end)
    end)
end)
