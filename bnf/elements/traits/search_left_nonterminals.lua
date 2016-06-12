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

local search_left_nonterminals = traits.search_left_nonterminals
local search_left_nonterminal = traits.search_left_nonterminal


search_left_nonterminals:where(factor, function(self, targets)
  for target in pairs(targets) do
    if search_left_nonterminal(self, target) then
      return true
    end
  end
  return false
end, 2)

search_left_nonterminals:where(any, function(self, targets)
  for target in pairs(targets) do
    if search_left_nonterminal(self, target) then
      return true
    end
  end
  return false
end, 2)

local return_false = function() return false end
local proxy_element = function(self, target, seen)
  return search_left_nonterminals(self.element, target, seen)
end

search_left_nonterminals:where(opt, proxy_element, 2)
search_left_nonterminals:where(rep, proxy_element, 2)
search_left_nonterminals:where("function", return_false)
search_left_nonterminals:where(term, return_false)
search_left_nonterminals:where(span, function(self, target)
  return search_left_nonterminals(self[1], target)
end, 2)
