local utils = require("bnf.utils")
local termize = require("bnf.elements.utils").termize

local prototype = utils.prototype
local torepresentation = utils.torepresentation

local opt = prototype("opt", function(self, element)
  return setmetatable({element=termize(element)}, self)
end)

function opt:__tostring()
  return torepresentation(term, {self.element})
end

function opt:__call(invariant, position, limit, peek, exclude, skip,
    given_rest, given_value)
  local rest, value = self.element(invariant, position, limit, peek, exclude,
    skip, given_rest, given_value)
  if not rest then
    return position
  end
  return rest, value
end

return opt
