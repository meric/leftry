local utils = require("bnf.utils")
local termize = require("bnf.elements.utils").termize
local traits = require("bnf.elements.traits")
local hash = traits.hash

local prototype = utils.prototype
local dotmap = utils.dotmap

local torepresentation = utils.torepresentation

local search_left_nonterminal = traits.search_left_nonterminal

local any = prototype("any", function(self, ...)
  return setmetatable({dotmap(termize, ...)}, self)
end)

function any:__tostring()
  return torepresentation(any, self)
end

function any:index()
  self.lookahead = {}
  self.reverse = {}
  for i=1, 255 do
    self.lookahead[i] = {}
  end
  for i=1, #self do
    self.reverse[self[i]] = i
    local h = {hash(self[i])}
    for j=1, #h do
      table.insert(self.lookahead[h[j]], self[i])
    end
  end
end

local cache = {}

local function skipping(skip, alternative)
  if not cache[skip] then
    cache[skip] = {}
  end
  local value = cache[skip][alternative]
  if value == nil then
    cache[skip][alternative] = false
    for nonterminal in pairs(skip) do
      if search_left_nonterminal(alternative, nonterminal) then
        cache[skip][alternative] = true
        return true
      end
    end
    return false
  end
  return cache[skip][alternative]
end

function any:__call(invariant, position, expect, peek, exclude, skip)
  if position > #invariant.src then
    return nil
  end
  local reducer = self.reducer
  if not self.lookahead then
    self:index()
  end
  local lookahead = self.lookahead
  local rest
  local value
  local alternatives = lookahead[invariant.src:byte(position)]
  local alternative
  for i=1, #alternatives do
    if not exclude or not exclude[alternatives[i]] then
      -- Note: A `rep` element in `any` acts like a non-optional element.
      if not skip or skipping(skip, alternatives[i]) then
        rest, value = alternatives[i](invariant, position, expect, peek,
          exclude, skip)
        if rest and rest ~= sub then
          alternative = self.reverse[alternatives[i]]
          break
        end
      end
    end
  end
  return rest, value, alternative
end

return any
