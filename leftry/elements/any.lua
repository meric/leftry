local utils = require("leftry.utils")
local termize = require("leftry.elements.utils").termize
local invariantize = require("leftry.elements.utils").invariantize
local traits = require("leftry.elements.traits")
local memoize = require("leftry.immutable.memoize")
local hash = traits.hash

local prototype = utils.prototype
local dotmap = utils.dotmap

local torepresentation = utils.torepresentation

local search_left_nonterminal = traits.search_left_nonterminal
local search_left_nonterminals = traits.search_left_nonterminals
local left_nonterminals = traits.left_nonterminals

local any = prototype("any", function(self, ...)
  return setmetatable({dotmap(termize, ...)}, self)
end)

function any:__tostring()
  return torepresentation(any, self)
end

function any:index()
  self.cache = {}
  self.reverse = {}
  for i=1, 255 do
    self.cache[i] = {}
  end
  for i=1, #self do
    self.reverse[self[i]] = i
    local h = {hash(self[i])}
    for j=1, #h do
      table.insert(self.cache[h[j]], self[i])
    end
  end
  return self.cache
end

local _search_left_nonterminals = memoize(search_left_nonterminals, 2)

function any:__call(invariant, position, peek, expect, exclude, nonterminals)
  invariant = invariantize(invariant)
  if position > #invariant.source then
    return
  end
  local alts = (self.cache or self:index())[invariant.source:byte(position)]
  for i=1, #alts do
    if not exclude or not exclude[alts[i]] then
      -- Note: A `rep` element in `any` acts like a non-optional element.
      if not nonterminals or
          _search_left_nonterminals[alts[i]][nonterminals] then
        local rest, value = alts[i](invariant, position, peek, expect,
          exclude, nonterminals)
        if rest and rest > position then
          return rest, value, self.reverse[alts[i]]
        end
      end
    end
  end
end

return any
