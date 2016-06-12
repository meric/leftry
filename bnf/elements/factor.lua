local opt = require("bnf.elements.opt")
local termize = require("bnf.elements.utils").termize
local utils = require("bnf.utils")
local traits = require("bnf.elements.traits")
local any = require("bnf.elements.any")

local set = require("bnf.immutable.set")
local set_insert, set_empty = set.insert, set.empty

local prototype = utils.prototype
local copy = utils.copy
local filter = utils.filter
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
  self.setup = function() return self.canon end
  self.recursions = any(unpack(filter(function(alt) return
    search_left_nonterminal(alt, self)
  end, self.canon)))
  return self.canon
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

function factor:alias(invariant, position, peek, expect, exclude, skip)
  return self.canon(invariant, position, peek, expect, exclude, skip)
end

function factor:wrap(invariant, position, peek, expect, exclude, skip)
  local rest, value, choice = self.canon(invariant, position, peek, expect,
    exclude, skip)
  if not peek and rest then
    return rest, self.initializer(value, self, position, rest, choice)
  end
  return rest, value
end

function factor:measure(invariant, rest, exclude, skip)
  local sections
  local n = 0
  local final
  local limit = #invariant.src
  local recursions = self.recursions

  while limit >= rest do
    local position = rest
    for i=1, #recursions do
      local alt = recursions[i]
      if not exclude[alt] then
        rest = alt(invariant, position, true, nil, nil, skip)
        if rest and rest ~= position then
          final = rest
          break
        end
      end
    end
    if not rest or position == rest then
      break
    elseif not sections then
      sections = {position, rest}
    else
      table.insert(sections, position)
      table.insert(sections, rest)  
    end
  end
  return final, sections
end

function factor.trace(top, invariant, skip, sections)
  local span = require("bnf.elements.span")
  local index = #sections/2
  local paths = {}
  while index > 0 do
    local position = sections[index*2-1]
    local expect   = sections[index*2]
    local rest, _, choice = top.canon(invariant, position, true, expect,
      exclude, skip)
    local alternative = top.canon[choice]
    table.insert(paths, {choice=choice, expect=expect, nonterminal=top})

    if getmetatable(alternative) ~= factor then
      index = index - 1
      top = alternative
      while getmetatable(top) == span do
        top = top[1]
      end
    else
      top = alternative
    end
    -- assert(getmetatable(top) == factor)
  end

  return top, paths
end

local exclude_cache = {}



function factor:left(invariant, position, peek, expect, exclude, skip,
    given_rest, given_value)
  if given_rest then
    if expect and expect ~= given_rest then
      return
    end
    return given_rest, given_value
  end

  if position > #invariant.src then
    return
  end

  exclude = set_insert(exclude or set_empty, self)

  local prefix_rest, prefix_value, prefix_choice = self.canon(invariant,
    position, peek, nil, exclude)

  if not prefix_rest then
    return
  elseif prefix_rest == expect then
    if peek then
      return prefix_rest
    end
    return prefix_rest, self.initializer(
      prefix_value, self, position, prefix_rest, prefix_choice)
  end

  local skip = left_nonterminals(self)

  local rest, sections = self:measure(invariant, prefix_rest, exclude, skip)

  if expect and (rest or prefix_rest) ~= expect then
    return
  end

  if peek then
    return rest or prefix_rest
  end

  if not sections then
    return prefix_rest, self.initializer(
      prefix_value, self, position, prefix_rest, prefix_choice)
  end

  local top, paths = self:trace(invariant, skip, sections)

  if not paths then
    return
  end

  local paths_length = #paths
  while getmetatable(top) == factor do
    local _, __, choice = top.canon(invariant, position, true, prefix_rest)
    if not choice or _ ~= prefix_rest then
      break
    end
    table.insert(paths, {choice=choice, expect=prefix_rest, nonterminal=top})
    top = top.canon[choice]
  end

  if paths_length == #paths then
    error("cannot find prefix")
  end

  local rest, value
  for i=#paths, 1, -1 do
    local path = paths[i]
    local top = path.nonterminal
    local alternative = top.canon[path.choice]
    if i == #paths then
      rest, value = alternative(invariant, position, peek, path.expect)
    else
      rest, value = alternative(invariant, position, peek, path.expect,
        nil, nil, paths[i+1].expect, value)
    end
    value = top.initializer(value, self, position, rest, path.choice)
  end
  return rest, value
end

function factor:call(invariant, position, peek, expect, exclude, skip,
    given_rest, given_value)
  if not self.canon then
    self:setup()
    self:actualize()
  end
  if search_left_nonterminal(self.canon, self) then
    self.call = self.left
  elseif self.initializer ~= factor.initializer then
    self.call = self.wrap
  else
    self.call = self.alias
  end
  return self:call(invariant, position, peek, expect, exclude, skip,
    given_rest, given_value)
end

function factor:__call(invariant, position, peek, expect, exclude, skip,
    given_rest, given_value)
  if skip and skip[self] then
    return self:alias(invariant, position, peek, expect, exclude, skip,
      given_rest, given_value)
  end
  return self:call(invariant, position, peek, expect, exclude, skip,
    given_rest, given_value)
end

return factor
