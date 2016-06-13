local utils = require("leftry.utils")
local termize = require("leftry.elements.utils").termize

local prototype = utils.prototype
local torepresentation = utils.torepresentation

local opt = prototype("opt", function(self, element)
  return setmetatable({element=termize(element)}, self)
end)

function opt:__tostring()
  return torepresentation(opt, {self.element})
end

function opt:__call(invariant, position, peek)
  local rest, value = self.element(invariant, position, peek)
  if not rest then
    return position
  end
  return rest, value
end

return opt
