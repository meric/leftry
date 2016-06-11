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
  self.setup = function() return self.canon end
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

function factor:alias(invariant, position, expect, peek, exclude, skip)
  return self.canon(invariant, position, expect, peek, exclude, skip)
end

function factor:wrap(invariant, position, expect, peek, exclude, skip)
  local rest, value, choice = self.canon(invariant, position, expect, peek,
    exclude, skip)
  if not peek and rest then
    return rest, self.initializer(value, self, position, rest, choice)
  end
  return rest, value
end

function factor:measure(invariant, rest, expect, exclude)
  if expect == rest then
    return
  end
  local sections
  local final
  local limit = #invariant.src
  while limit >= rest do
    local position = rest
    for i=1, #self.canon do
      if search_left_nonterminal(self.canon[i], self)
          and (not exclude or not exclude[self.canon[i]]) then
        local skip = traits.left_nonterminals(self)
        skip[self] = true
        local alternative = self.canon[i]
        rest = alternative(invariant, position, nil, true, nil, skip)
        if rest and rest ~= position or (expect and rest == expect) then
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
    table.insert(sections, {position=position, expect=rest})
    if expect and rest == expect then
      break
    end
  end
  if final then
    assert(final == sections[#sections].expect)
  end
  return final, sections
end

function factor.trace(top, invariant, skip, sections)

  local span = require("bnf.elements.span")
  local index = #sections
  local paths = {}
  while index > 0 do
    local section = sections[index]
    local position, expect = section.position, section.expect
    local rest, _, choice = top.canon(invariant, position, expect, true,
      exclude, skip)
    assert(rest)
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
    assert(getmetatable(top) == factor)
  end

  return top, paths
end

function factor:left(invariant, position, expect, peek, exclude, skip,
    given_rest, given_value)
  local span = require("bnf.elements.span")
  if given_rest then
    if expect and expect ~= given_rest then
      return
    end
    return given_rest, given_value
  end

  if position > #invariant.src then
    return
  end

  local orig_exclude = exclude
  if not exclude or not exclude[self] then
    exclude = rawset(copy(exclude or {}), self, true)
  end

  local prefix_rest, prefix_value, prefix_choice = self.canon(invariant,
    position, nil, peek, exclude)

  if not prefix_rest then
    return
  end

  local rest, sections = self:measure(invariant, prefix_rest, expect,
    orig_exclude)

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

  skip = rawset(copy(skip or {}, traits.left_nonterminals(self)), self,
    true)

  local top, paths = self:trace(invariant, skip, sections)

  if not paths then
    return
  end

  local paths_length = #paths
  while getmetatable(top) == factor do
    local _, __, choice = top.canon(invariant, position, prefix_rest, true)
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
      rest, value = alternative(invariant, position, path.expect, peek)
    else
      rest, value = alternative(invariant, position, path.expect, peek,
        nil, nil, paths[i+1].expect, value)
    end
    value = top.initializer(value, self, position, rest, path.choice)
  end
  return rest, value
end

function factor:call(invariant, position, expect, peek, exclude, skip,
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
  return self:call(invariant, position, expect, peek, exclude, skip,
    given_rest, given_value)
end

function factor:__call(invariant, position, expect, peek, exclude, skip,
    given_rest, given_value)
  if skip and skip[self] then
    return self:alias(invariant, position, expect, peek, exclude, skip,
      given_rest, given_value)
  end
  return self:call(invariant, position, expect, peek, exclude, skip,
    given_rest, given_value)
end

return factor
