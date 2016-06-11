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

local hash = traits.hash
local search_left_nonterminal = traits.search_left_nonterminal

local all = function()
  local t = {}
  for i=1, 255 do
    table.insert(t, i)
  end
  return unpack(t)
end

hash:where(any, function(self)
  local t = {}
  for i=1, #self do
    local h = {hash(self[i])}
    for j=1, #h do
      table.insert(t, h[j])
    end
  end
  return unpack(t)
end)

hash:where(factor, function(self)
  if search_left_nonterminal(self.canon or self:setup(), self) then
    return all()
  end
  return hash(self.canon)
end)

hash:where("function", all)

hash:where(term, function(self)
  return string.byte(self.constant)
end)

hash:where(opt, function(self)
  return hash(self.element)
end)

hash:where(rep, function(self)
  return hash(self.element)
end)

hash:where(span, function(self)
  local t = {}
  for i=1, #self do
    local h = {hash(self[i])}
    for j=1, #h do
      table.insert(t, h[j])
    end
    local mt = getmetatable(self[i])
    if mt ~= opt and mt ~= rep then
      break
    end
  end
  if self.spaces then
    for i=1, #self.spaces do
      table.insert(t, self.spaces:byte(i))
    end
  end
  return unpack(t)
end)
