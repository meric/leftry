local grammar = require("bnf.grammar")
local traits = require("bnf.elements.traits")
local set = require("bnf.immutable.set")

local set_insert, set_empty = set.insert, set.empty

local any = grammar.any
local span = grammar.span
local opt = grammar.opt
local rep = grammar.rep
local term = grammar.term
local factor = grammar.factor

local search_left_nonterminal = traits.search_left_nonterminal


search_left_nonterminal:where(factor, function(self, target, seen)
  if self == target then
    return true
  end
  if seen and seen[self] then
    return false
  end
  return search_left_nonterminal(self.canon or self:setup(), target,
    set_insert(seen or set_empty, self))
end, 2)

search_left_nonterminal:where(any, function(self, target, seen)
  for i=1, #self do
    if search_left_nonterminal(self[i], target, seen) then
      return true
    end
  end
  return false
end, 2)

local return_false = function() return false end
local proxy_element = function(self, target, seen)
  return search_left_nonterminal(self.element, target, seen)
end

search_left_nonterminal:where(opt, proxy_element, 2)
search_left_nonterminal:where(rep, proxy_element, 2)
search_left_nonterminal:where("function", return_false)
search_left_nonterminal:where(term, return_false)
search_left_nonterminal:where(span, function(self, target, seen)
  return search_left_nonterminal(self[1], target, seen)
end, 2)
