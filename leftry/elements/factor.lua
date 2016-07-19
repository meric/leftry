local opt = require("leftry.elements.opt")
local termize = require("leftry.elements.utils").termize
local invariantize = require("leftry.elements.utils").invariantize
local utils = require("leftry.utils")
local traits = require("leftry.elements.traits")
local any = require("leftry.elements.any")

local set = require("leftry.immutable.set")
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
  for i, v in ipairs(canon) do
    table.insert(self, v)
  end
  self.canonize = function() return canon end
  self.actualize = function() end
end

function factor:wrap(invariant, position, peek, expect, exclude, skip)
  local rest, value, choice = self.canon(invariant, position, peek, expect,
    exclude, skip)
  if not peek and rest and rawget(self, "initializer") then
    return rest, self.initializer(value, self, position, rest, choice)
  end
  return rest, value
end

function factor:measure(invariant, rest, exclude, skip)
  local sections
  local done = rest
  local recursions = self.recursions
  local length = #invariant.source

  while rest and length >= rest do
    local position = rest
    for i=1, #recursions do
      local alt = recursions[i]
      if not exclude[alt] then
        rest = alt(invariant, position, true, nil, nil, skip)
        if rest and rest > position then
          done = rest
          if not sections then
            sections = {position, rest}
          else
            table.insert(sections, position)
            table.insert(sections, rest)
          end
          break
        end
      end
    end
  end
  return done, sections
end

function factor.trace(top, invariant, skip, sections)
  local span = require("leftry.elements.span")
  local index = #sections/2
  local paths = {}
  while index > 0 do
    local position = sections[index*2-1]
    local expect   = sections[index*2]
    local rest, _, choice = top.canon(invariant, position, true, expect,
      nil, skip)
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

function factor:left(invariant, position, peek, expect, exclude)
  if position > #invariant.source then
    return
  end

  exclude = set_insert(exclude or set_empty, self)

  local prefix_rest, value, choice = self.canon(invariant,
    position, peek, nil, exclude)

  if not prefix_rest then
    return
  elseif prefix_rest == expect then
    return prefix_rest, not peek and self.initializer(value, self, position,
      prefix_rest, choice) or nil
  end

  local skip = self.left_nonterminals
  local rest, sections = self:measure(invariant, prefix_rest, exclude, skip)

  if expect and rest ~= expect then
    return
  end

  if peek then
    if invariant.subscribers and invariant.subscribers[self] then
      invariant.subscribers[self](self, position, rest, peek)
    end
    return rest
  end

  if not sections then
    return rest, self.initializer(value, self, position, rest, choice)
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
    elseif getmetatable(alternative) == factor then
      rest, value = paths[i+1].expect, value
    else
      rest, value = alternative(invariant, position, peek, path.expect,
        nil, nil, paths[i+1].expect, value)
    end
    value = top.initializer(value, self, position, rest, path.choice)
  end
  if invariant.subscribers and invariant.subscribers[self] then
    invariant.subscribers[self](self, position, rest, peek)
  end
  return rest, value
end

function factor:call(invariant, position, peek, expect, exclude)
  if not self.canon then
    self:setup()
    self:actualize()
  end
  if not self.left_nonterminals then
    self.left_nonterminals = left_nonterminals(self)
  end
  if search_left_nonterminal(self.canon, self) then
    self.call = self.left
  else
    self.call = self.wrap
  end
  return self:call(invariant, position, peek, expect, exclude)
end

function factor:__call(invariant, position, peek, expect, exclude, skip)
  invariant = invariantize(invariant)
  local rest, value
  if skip and skip[self] then
    rest, value = self.canon(invariant, position, peek, expect, exclude, skip)
  else
    rest, value = self:call(invariant, position, peek, expect, exclude)
  end
  if rest and invariant.events[self] then
    invariant.events[self](position, rest, value, peek)
  end
  return rest, value
end

function factor:match(text, nonterminal, pattern, index)
  assert(type(text) == "string")
  pattern = pattern or nonterminal
  local invariant = invariantize(text)
  local matched, index
  self({
    source=text,
    events={
      [nonterminal] = function(position, rest)
        if matched == nil and position >= (index or 1) then
          if pattern(invariant, position, true) then
            matched, index = select(2, pattern(invariant, position)), position
          end
        end
      end
    }}, 1, true)
  return matched
end

function factor:find(text, nonterminal, pattern, from)
  assert(type(text) == "string")
  pattern = pattern or nonterminal
  local invariant = invariantize(text)
  local index, to
  self({
    source=text,
    events={
      [nonterminal] = function(position, rest)
        if index == nil and position >= (from or 1) then
          if pattern(invariant, position, true) then
            index = position
            to = rest - 1
          end
        end
      end
    }}, 1, true)
  return index, to
end

function factor:gfind(text, nonterminal, pattern)
  pattern = pattern or nonterminal
  local invariant = invariantize(text)
  local thread = coroutine.create(function()

    self({source=text, events={
      [nonterminal] = function(position, rest)
        if pattern(invariant, position, true) then
          coroutine.yield(position, rest - 1)
        end
      end}
    }, 1, true)
  end)
  return function()

    local ok, position, rest = coroutine.resume(thread)
    -- print(ok, "hello", position, rest)
    if ok then
      return position, rest
    end
  end
end

function factor:gmatch(text, nonterminal, pattern)
  pattern = pattern or nonterminal
  local invariant = invariantize(text)
  local thread = coroutine.create(function()
    self({source=text, events={
      [nonterminal] = function(position, rest)
        if pattern(invariant, position, true) then
          coroutine.yield(select(2, pattern(invariant, position)), position)
        end
      end}
    }, 1, true)
  end)
  return function()
    local ok, position, rest = coroutine.resume(thread)
    if ok then
      return position, rest
    end
  end
end

return factor
