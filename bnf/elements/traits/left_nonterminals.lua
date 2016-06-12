local grammar = require("bnf.grammar")
local traits = require("bnf.elements.traits")
local utils = require("bnf.utils")
local set = require("bnf.immutable.set")

local set_insert, set_empty = set.insert, set.empty

local any = grammar.any
local span = grammar.span
local opt = grammar.opt
local rep = grammar.rep
local term = grammar.term
local factor = grammar.factor

local contains = utils.contains

local search_left_nonterminal = traits.search_left_nonterminal
local left_nonterminals = traits.left_nonterminals


left_nonterminals:where(factor, function(self, nonterminals)
  self:setup()
  if #self.recursions == 0 then
    return set_empty
  end
  if nonterminals and nonterminals[self] then
    return nonterminals
  end
  nonterminals = set_insert(nonterminals or set_empty, self)
  for i, alt in ipairs(self.recursions) do
    nonterminals = left_nonterminals(alt, nonterminals)
  end
  return nonterminals
end, 1)

local return_empty = function() return set_empty end
local proxy_element = function(self, nonterminals)
  return left_nonterminals(self.element, nonterminals)
end

left_nonterminals:where("function", return_empty)
left_nonterminals:where(opt, proxy_element, 2)
left_nonterminals:where(rep, proxy_element, 2)
left_nonterminals:where(term, return_empty)
left_nonterminals:where(span, function(self, nonterminals)
  return left_nonterminals(self[1], nonterminals)
end)
