local utils = require("bnf.utils")
local prototype = utils.prototype
local dotmap = utils.dotmap
local map = utils.map
local torepresentation = utils.torepresentation

local term = prototype("term", function(self, constant, initializer)
  return setmetatable({constant=constant, initializer=initializer}, self)
end)

function term:__tostring()
  return torepresentation(term, {self.constant})
end

function term:__mod(initializer)
  return rawset(self, "initializer", initializer)
end

function term:__call(invariant, position, peek)
  local constant = self.constant
  local count = #constant
  local initializer = self.initializer
  local rest = position + count
  if position > #invariant.src or
    invariant.src:sub(position, rest - 1) ~= constant then
    return nil
  end
  if initializer and not peek then
    return rest, initializer(constant, self, position, rest)
  end
  return rest, constant
end

return term
