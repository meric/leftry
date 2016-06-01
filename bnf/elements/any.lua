local utils = require("bnf.utils")
local termize = require("bnf.elements.utils").termize
local hash = require("bnf.elements.traits.hash")

local prototype = utils.prototype
local dotmap = utils.dotmap

local torepresentation = utils.torepresentation

local any = prototype("any", function(self, ...)
  return setmetatable({dotmap(termize, ...)}, self)
end)

function any:__tostring()
  return torepresentation(any, self)
end

function any:index()
  self.lookahead = {}
  for i=1, 255 do
    self.lookahead[i] = {}
  end
  for i=1, #self do
    local h = {hash(self[i])}
    for j=1, #h do
      table.insert(self.lookahead[h[j]], self[i])
    end
  end
end

function any:__call(invariant, position, limit, peek, exclude, skip)
  limit = limit or #invariant.src
  if position > limit then
    return nil
  end
  local reducer = self.reducer
  if not self.lookahead then
    self:index()
  end
  local lookahead = self.lookahead
  local rest = position
  local value
  local alternatives = lookahead[invariant.src:byte(position)]
  local alternative
  for i=1, #alternatives do
    -- Note: A `rep` element in `any` acts like a non-optional element.
    rest, value = alternatives[i](invariant, position, limit, peek, exclude,
      skip)
    if rest and rest ~= sub then
      alternative = i
      break
    end
  end
  return rest, value, alternative
end

return any
