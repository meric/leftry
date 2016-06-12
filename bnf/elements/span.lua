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


local term = require("bnf.elements.term")
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

function span:__call(invariant, position, peek, expect, exclude, skip,
    given_rest, given_value)
  if position > #invariant or (exclude and exclude[self[1]]) then
    return nil
  end
  local rest = position
  local reducer = self.reducer
  local values
  local first = 1
  if skip and skip[self[1]] then
    -- A skip argument means we want to run an alternative beginning with
    -- a left nonterminal that appears in the skip table, and then parse
    -- by skipping that left nonterminal.
    -- If this span does not fit that criteria, we should abort.
    -- Otherwise, we begin parsing by skipping the first element.
    if getmetatable(self[1]) ~= factor and 
        not search_left_nonterminal(self[1], self[1]) then
      return
    end
    first = first + 1
  end

  if self.spacing then
    -- Apply spacing rule at beginning of span.
    rest = self.spacing(invariant, rest, nil, self[1])
  end

  for i=first, #self do 
    local value
    local sub = rest or position
    if i > 1 then
      skip = nil
      exclude = nil
    end
    if i ~= 1 then
      given_rest, given_value = nil, nil
    end
    rest, value = self[i](invariant, sub, peek, nil, exclude, skip,
      given_rest, given_value)
    if not rest then
      return nil
    end
    if not peek then
      values = reducer(values, value, i, self, sub, rest)
    end
    if rest and self.spacing then
      -- Apply spacing rule between each element.
      rest = self.spacing(invariant, rest, self[i], self[i+1])
      if not rest then
        return nil
      end
    end
  end
  if expect and rest ~= expect or rest == position then
    return
  end
  return rest, values
end

return span
