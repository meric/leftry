local utils = require("bnf.utils")
local termize = require("bnf.elements.utils").termize

local prototype = utils.prototype
local torepresentation = utils.torepresentation

local rep = prototype("rep", function(self, element, reducer)
  return setmetatable({element=termize(element), reducer=reducer}, self)
end)

function rep:__tostring()
  return torepresentation(term, {self.element})
end

function rep.reducer(initial, value, self, position, rest, i)
  return rawset(initial or {}, i, value)
end

function rep:__mod(reducer)
  return rawset(self, "reducer", reducer)
end

function rep:__call(invariant, position, expect, peek, exclude, skip,
    given_rest, given_value)
  local initial
  local rest = position
  local element = self.element
  local i = 1
  while true do
    local sub = rest
    if sub > #invariant.src then
      return rest, initial
    end
    rest, value = element(invariant, sub, limit, peek, exclude, skip,
      given_rest, given_value)
    if not rest or (expect and rest == expect) or rest == position then
      return sub, initial
    end
    if not peek then
      initial = self.reducer(initial, value, self, sub, rest, i)
      i = i + 1
    end
  end
end

return rep
