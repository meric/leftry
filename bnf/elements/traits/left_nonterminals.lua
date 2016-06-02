local grammar = require("bnf.grammar")
local traits = require("bnf.elements.traits")
local utils = require("bnf.utils")

local any = grammar.any
local span = grammar.span
local opt = grammar.opt
local rep = grammar.rep
local term = grammar.term
local factor = grammar.factor

local contains = utils.contains

local search_left_nonterminal = traits.search_left_nonterminal
local left_nonterminals = traits.left_nonterminals

left_nonterminals:where(factor, function(self, stack)
  self:setup()

  stack = stack or {}

  if contains(stack, self) then
    return stack
  end

  if not search_left_nonterminal(self.canon, self) then
    return {}
  end

  table.insert(stack, 1, self)

  for i=1, #self.canon do
    if search_left_nonterminal(self.canon[i], self) then
      left_nonterminals(self.canon[i], stack)
    end
  end

  return stack
end)

left_nonterminals:where("function", function() return {} end)

left_nonterminals:where(opt, function(self, stack)
  return left_nonterminals(self.element, stack)
end)

left_nonterminals:where(rep, function(self, stack)
  return left_nonterminals(self.element, stack)
end)


left_nonterminals:where(term, function() return {} end)

left_nonterminals:where(span, function(self, stack)
  if #self > 0 then
    return left_nonterminals(self[1], stack)
  end
  return {}
end)
