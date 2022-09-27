#!/usr/bin/env lua

local lust = require 'test.lust'

local describe = lust.describe
local expect = lust.expect
local it = lust.it

local utils = require 'src.utils'

lust.paths.match = {
    test = function(value, pattern)
        if type(value) ~= 'string' then value = tostring(value) end
        local result = string.find(value, pattern)
        return result ~= nil, 'expected ' .. value .. ' to match pattern [[' .. pattern .. ']]',
        'expected ' .. value .. ' to not match pattern [[' .. pattern .. ']]'
    end
}
table.insert(lust.paths.to, 'match')
table.insert(lust.paths.to_not, 'match')

describe('testing testing', function ()
    it('matching!', function ()
        expect('RED').to_not.match('BLUE')
        expect('REDDIT').to.match('RED')
        expect(utils.Array{1, 2, 3}).to.match('Array {%d+, %d+, %d+}')
    end)
end)

describe('Test Utilities', function()

    describe('Array', function()
        local Array = utils.Array
        describe('metamethods', function()
            it('__call', function()
                -- we can call this
                expect(Array).to_not.fail()
                -- we can call it with a table argument
                expect(function() Array {15, 23} end).to_not.fail()
                -- we can call it with other types
                expect(function() Array {"hi", "mom!"} end).to_not.fail()
                -- we can call with mixed type
                expect(function()
                    Array {"string!", 2, function() end, {}, 0.3}
                end).to_not.fail()
            end)

            it('__eq', function()
                -- Arrays with the same things are equal
                expect(Array()).to.equal(Array())
                expect(Array {1, 2, 3}).to.equal(Array {1, 2, 3})

                local t = {15, 30, 45}
                expect(Array(t)).to.equal(Array(t))

                -- Arrays with different things are unequal
                expect(Array {1}).to_not.be(Array {2})
                -- if we use hash keys, then we ignore them
                expect(Array {1, 2, 3, red = 0, blue = 0, green = 0}).to.equal(
                    Array {1, 2, 3})
            end)

            it('__name', function()
                -- I have set the name correctly
                expect(getmetatable(Array).__name).to.equal("Array")
            end)

            it('__tostring', function()
                -- empty arrays render properly
                expect(tostring(Array())).to.equal("Array {}")
                -- fuller arrays render properly
                expect(tostring(Array {1, 2})).to.equal("Array {1, 2}")
                -- strings render properly
                expect(tostring(Array {'@', 3, 4, '2'})).to.equal(
                    'Array {"@", 3, 4, "2"}')
            end)

            it('__add', function()
                -- add an array to an array
                expect(Array {"A", "B"} + Array {"C", "D"}).to.be(Array {
                    "A", "B", "C", "D"
                })
                -- add a table to an array
                expect(Array {1, 2} + {3, 4}).to.equal(Array {1, 2, 3, 4})
                -- add an array to a table
                expect({1, 2} + Array {3, 4}).to.equal(Array {1, 2, 3, 4})
                -- add a random object to an array
                expect(Array {'$', '#'} + '%').to.equal(Array {'$', '#', '%'})
                -- add an array to a random object
                expect(0.15 + Array {0.255, 0.23}).to.equal(Array {
                    0.15, 0.255, 0.23
                })
            end)
        end)

        describe('methods', function()
            it('len', function()
                expect(Array():len()).to.equal(0)
                expect(Array({0, 0, 0}):len()).to.equal(3)
            end)
            it('append', function()
                expect(Array {2}:append('2')).to.equal(Array {2, '2'})
                expect(Array():append(1):len()).to.equal(1)
                expect(Array {'3'}:append('4')).to.equal(Array {'3', '4'})
            end)
            it('range', function()
                expect(Array.range(3)).to.equal(Array {1, 2, 3})
                expect(Array.range(10, 15)).to
                    .be(Array {10, 11, 12, 13, 14, 15})
                expect(Array.range(10, -14)).to.be(Array())
                expect(Array.range(-3)).to.be(Array())
                expect(Array.range('$')).to.be(Array())
            end)
            it('filter', function()
                expect(Array.range(100):filter(function(n)
                    return (n % 3) == 0
                end):len()).to.equal(33)
            end)
            it('pop', function()
                expect(Array {1, 2}:pop()).to.equal(2)
                expect(Array():pop()).to.fail()
            end)
            it('remove', function()
                expect(Array {1, 2, 3}:remove(2)).to.equal(2)
                expect(Array({1}):remove(10)).to.fail()
            end)
        end)
    end)
end)
