require("leftry.elements.traits.hash")
require("leftry.elements.traits.left_nonterminals")
require("leftry.elements.traits.search_left_nonterminal")
require("leftry.elements.traits.search_left_nonterminals")

local function match(invariant, entry, nonterminal, predicate, index)
  local matched
  local initializer = rawget(nonterminal, "initializer")
  function nonterminal.initializer(value, self, position, rest, choice)
    if matched == nil and position >= (index or 1)
        and (predicate or nonterminal)(invariant, position, true) then
      if predicate then
        value = select(2, predicate(invariant, position))
      end
      matched = value
    end
    return value
  end
  entry(invariant, 1)
  nonterminal.initializer = initializer
  return matched
end

local function find(invariant, entry, nonterminal, predicate, index)
  local matched, till
  local initializer = rawget(nonterminal, "initializer")
  function nonterminal.initializer(value, self, position, rest, choice)
    if matched == nil and position >= (index or 1)
        and (not predicate or predicate(invariant, position, true)) then
      matched, till = position, rest-1
    end
  end
  entry(invariant, 1)
  nonterminal.initializer = initializer
  return matched, till
end


local function gfind(invariant, entry, nonterminal, predicate)
  local matches = {}
  local initializer = rawget(nonterminal, "initializer")
  function nonterminal.initializer(value, self, position, rest, choice)
    if matched == nil
        and (not predicate or predicate(invariant, position, true)) then
      table.insert(matches, position)
      table.insert(matches, rest - 1)
    end
    return
  end
  entry(invariant, 1)
  nonterminal.initializer = initializer
  local i = -1
  return function()
    i = i + 2
    return matches[i], matches[i+1]
  end
end

local function gmatch(invariant, entry, nonterminal, predicate)
  local matches = {}
  local initializer = rawget(nonterminal, "initializer")
  function nonterminal.initializer(value, self, position, rest, choice)
    if (predicate or nonterminal)(invariant, position, true) then
      if predicate then
        value = select(2, predicate(invariant, position))
      end
      table.insert(matches, value)
    end
    return value
  end
  entry(invariant, 1)
  nonterminal.initializer = initializer
  local i = 0
  return function()
    i = i + 1
    return matches[i]
  end
end

return {
    grammar = require("leftry.grammar"),
    span = require("leftry.elements.span"),
    any = require("leftry.elements.any"),
    term = require("leftry.elements.term"),
    factor = require("leftry.elements.factor"),
    opt = require("leftry.elements.opt"),
    rep = require("leftry.elements.rep"),
    utils = require("leftry.utils"),
    trait = require("leftry.trait"),
    gmatch = gmatch,
    match = match,
    find = find,
    gfind = gfind
}
