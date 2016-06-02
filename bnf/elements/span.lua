local opt = require("bnf.elements.opt")
local termize = require("bnf.elements.utils").termize
local utils = require("bnf.utils")
local factor = require("bnf.elements.factor")
local traits = require("bnf.elements.traits")

local prototype = utils.prototype
local dotmap = utils.dotmap
local map = utils.map
local torepresentation = utils.torepresentation

local search_left_nonterminal = utils.search_left_nonterminal


local span = prototype("span", function(self, ...)
  assert(select("#", ...) > 1, "span must consist of two or more elements.")
  return setmetatable({dotmap(termize, ...)}, self)
end)

function span.reducer(initial, value, self, position, rest, i)
  return rawset(initial or {}, i, value)
end

function span:__mod(reducer)
  return rawset(self, "reducer", reducer)
end

function span:__tostring()
  return torepresentation(span, self)
end

function span:__call(invariant, position, expect, peek, exclude, skip,
    given_rest, given_value)
  if position > #invariant.src or (exclude and exclude[self[1]]) then
    return nil
  end
  local rest = position
  local reducer = self.reducer
  local values
  local first = 1
  if skip and skip[self[1]] then
    if getmetatable(self[1]) ~= factor and 
        not search_left_nonterminal(self[1], self[1]) then
      return
    end
    first = first + 1
  end
  for i=first, #self do 
    local value
    local sub = rest
    if i > 1 then
      skip = nil
    end
    if i ~= 1 then
      given_rest, given_value = nil, nil
    end
    rest, value = self[i](invariant, rest, nil, peek, exclude, skip,
      given_rest, given_value)
    if not rest then
      return nil
    end
    if not peek then
      values = reducer(values, value, self, sub, rest, i)
    end
  end
  if expect and rest ~= expect then
    return
  end
  return rest, values
end

return span
