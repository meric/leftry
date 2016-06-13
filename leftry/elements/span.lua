local opt = require("leftry.elements.opt")
local termize = require("leftry.elements.utils").termize
local utils = require("leftry.utils")
local factor = require("leftry.elements.factor")
local traits = require("leftry.elements.traits")

local prototype = utils.prototype
local dotmap = utils.dotmap
local map = utils.map
local torepresentation = utils.torepresentation

local search_left_nonterminal = utils.search_left_nonterminal
local left_nonterminals = traits.left_nonterminals


local term = require("leftry.elements.term")
local span = prototype("span", function(self, ...)
  assert(select("#", ...) > 1, "span must consist of two or more elements.")
  return setmetatable({dotmap(termize, ...)}, self)
end)

function span:__pow(options)
  -- Apply white spacing rule.
  for k, v in pairs(options) do
    self[k] = v
    assert(k == "spacing" or k == "spaces")
  end
  return self
end

function span.reducer(initial, value, i, self, position, rest)
  return rawset(initial or {}, i, value)
end

function span:__mod(reducer)
  return rawset(self, "reducer", reducer)
end

function span:__tostring()
  return torepresentation(span, self)
end

function span:__call(invariant, position, peek, expect, met, nonterminals,
    given_rest, given_value)

  if position > #invariant or met and met[self[1]] then
    return
  end

  local rest, reducer, spacing, values = position, self.reducer, self.spacing

  if not nonterminals or not nonterminals[self[1]] then
    if spacing then
      rest = spacing(invariant, rest, nil, self[1])
      if not rest then
        return
      end
    end
    local value
    if given_rest then
      rest, value = given_rest, given_value
    else
      rest, value = self[1](invariant, rest, peek, nil, met, nonterminals)
      if not rest then
        return
      end
    end
    if not peek then
      values = reducer(values, value, 1, self, position, rest)
    end
  end
  if spacing then
    rest = spacing(invariant, rest, self[1], self[2])
    if not rest then
      return
    end
  end
  for i=2, #self do
    local sub = rest
    local value
    rest, value = self[i](invariant, sub, peek)
    if not rest then
      return
    end
    if not peek then
      values = reducer(values, value, i, self, sub, rest)
    end
    if spacing then
      rest = spacing(invariant, rest, self[i], self[i+1])
      if not rest then
        return
      end
    end
  end
  return rest, values
end

return span
