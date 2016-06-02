local opt = require("bnf.elements.opt")
local termize = require("bnf.elements.utils").termize
local utils = require("bnf.utils")
local traits = require("bnf.elements.traits")
local any = require("bnf.elements.any")

local prototype = utils.prototype
local copy = utils.copy
local set = utils.set
local search_left_nonterminal = traits.search_left_nonterminal
local left_nonterminals = traits.left_nonterminals

local factor = prototype("factor", function(self, name, canonize, initializer)
  return setmetatable({
    name=name,
    canonize=canonize,
    initializer=initializer}, self)
end)

function factor.initializer(value, self, position, rest, choice)
  return value
end

function factor:__tostring()
  return self.name
end

function factor:setup()
  self.canon = self:canonize()
  if getmetatable(self.canon) ~= any then
    local canonize = self.canonize
    self.canonize = function()
      return any(canonize(self))
    end
    self.canon = self:canonize()
  end
  self.setup = function() end
end

function factor:actualize()
  -- Prioritise left recursion alternatives.
  local canon = self.canon
  table.sort(canon, function(a, b)
    return search_left_nonterminal(a, self)
      and not search_left_nonterminal(b, self)
  end)
  self.canonize = function() return canon end
  self.actualize = function() end
end

function factor:alias(invariant, position, limit, peek, exclude, skip)
  return self.canon(invariant, position, limit, peek, exclude, skip)
end

function factor:wrap(invariant, position, limit, peek, exclude, skip)
  local rest, value, choice = self.canon(invariant, position, limit, peek,
    exclude, skip)
  if not peek and rest then
    return rest, self.initializer(value, self, position, rest, choice)
  end
  return rest, value
end

function factor:measure(invariant, rest, limit)
  local sections
  local final
  while limit >= rest do
    local position = rest
    for i=1, #self.canon do
      if search_left_nonterminal(self.canon[i], self) then
        local skip = set(traits.left_nonterminals(self))
        skip[self] = true
        rest = self.canon[i](invariant, position, limit, true, nil, skip)
        if rest then
          final = rest
          break
        end
      end
    end
    if not rest or position == rest then
      break
    end
    if not sections then
      sections = {}
    end
    table.insert(sections, {position=position, limit=rest-1})
  end
  return final, sections
end

function factor.trace(top, invariant, skip, sections)
  local span = require("bnf.elements.span")
  local index = #sections
  local paths = {}
  while index > 0 do
    local section = sections[index]
    local position, limit = section.position, section.limit

    local rest, _, choice = top.canon(invariant, position, limit, true,
      exclude, skip)
    assert(rest)
    local alternative = top.canon[choice]

    table.insert(paths, {choice=choice, limit=limit, nonterminal=top})

    if getmetatable(alternative) ~= factor then
      index = index - 1
      top = alternative
      while getmetatable(top) == span do
        top = top[1]
      end
    else
      top = alternative
    end
  end

  return top, paths
end

function factor:left(invariant, position, limit, peek, exclude, skip,
    given_rest, given_value)
  if given_rest then
    return given_rest, given_value
  end

  limit = limit or #invariant.src

  if not exclude or not exclude[self] then
    exclude = rawset(copy(exclude or {}), self, true)
  end

  local prefix_rest, prefix_value, prefix_choice = self.canon(invariant,
    position, limit, peek, exclude)

  if not prefix_rest then
    return nil
  end

  if limit < prefix_rest then

    return prefix_rest, self.initializer(
      prefix_value, self, position, prefix_rest, prefix_choice)
  end

  local rest, sections = self:measure(invariant, prefix_rest, limit)

  if peek then
    return rest or prefix_rest
  end

  if not sections then
    return prefix_rest, self.initializer(
      prefix_value, self, position, prefix_rest, prefix_choice)
  end

  if not skip or not skip[self] then
    skip = rawset(copy(skip or {}, set(traits.left_nonterminals(self))), self,
      true)
  end

  local top, paths = self:trace(invariant, skip, sections)

  while getmetatable(top) == factor do
    local _, __, choice = top.canon(invariant, position, prefix_rest-1, true,
      exclude)
    -- we want  limit to act as minimum here. floor.
    -- change limit to rest. instead of doing position > limit, 
    -- we do position > #invariant.src and not limit or rest == limit
    -- rename limit to expect
    table.insert(paths, {choice=choice, limit=prefix_rest-1, nonterminal=top})
    top = top.canon[choice]
  end

  local rest, value
  for i=#paths, 1, -1 do
    local path = paths[i]
    local top = path.nonterminal
    local alternative = top.canon[path.choice]
    if i == #paths then
      rest, value = alternative(invariant, position, path.limit, peek)
    else
      rest, value = alternative(invariant, position, path.limit, peek,
        nil, nil, paths[i+1].limit + 1, value)
    end
    value = top.initializer(value, self, position, rest, path.choice)
  end
  return rest, value
end

function factor:call(invariant, position, limit, peek, exclude, skip,
    given_rest, given_value)
  self:setup()
  self:actualize()
  if search_left_nonterminal(self.canon, self) then
    self.call = self.left
  elseif self.initializer ~= factor.initializer then
    self.call = self.wrap
  else
    self.call = self.alias
  end
  return self:call(invariant, position, limit, peek, exclude, skip,
    given_rest, given_value)
end

function factor:__call(invariant, position, limit, peek, exclude, skip,
    given_rest, given_value)
  return self:call(invariant, position, limit, peek, exclude, skip,
    given_rest, given_value)
end

return factor
