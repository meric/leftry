local grammar = require("bnf.grammar")
local traits = require("bnf.elements.traits")

local any = grammar.any
local span = grammar.span
local opt = grammar.opt
local rep = grammar.rep
local term = grammar.term
local factor = grammar.factor

local search_left_nonterminal = traits.search_left_nonterminal

search_left_nonterminal:where("function", function() return false end)
search_left_nonterminal:where(term, function() return false end)

search_left_nonterminal:where(factor, function(self, target, seen)
  if self == target then
    return true
  end
  if seen and seen[self] then
    return false
  end
  seen = seen or {}
  seen[self] = true
  self:setup()
  return search_left_nonterminal(self.canon, target, seen)
end, 2)

search_left_nonterminal:where(any, function(self, target, seen)
  for i=1, #self do
    if search_left_nonterminal(self[i], target, seen) then
      return true
    end
  end
  return false
end, 2)

search_left_nonterminal:where(span, function(self, target, seen)
  if search_left_nonterminal(self[1], target, seen) then
    return true
  end
  return false
end, 2)

search_left_nonterminal:where(opt, function(self, target, seen)
  return search_left_nonterminal(self.element, target, seen)
end)

search_left_nonterminal:where(rep, function(self, target, seen)
  return search_left_nonterminal(self.element, target, seen)
end)
