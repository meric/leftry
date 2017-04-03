local utils = require("leftry.utils")
local prototype = utils.prototype
local map = utils.map

local unpack = table.unpack or unpack


-- Create a reducer to be used with `span`.
-- For now, see leftry/language/lua.lua for usage.
local function reduce(name, indices, __tostring)
  local reverse = {}
  local template = {}
  local terms = {}
  local arguments = {}
  local proto = prototype(name, function(self, values, value, i, _, index, rest)
    if not values then
      values = setmetatable({index=index, rest=rest}, self)
    end
    if not indices or reverse[i] then
      values[i] = value
    end
    values.rest = rest
    return values
  end)

  proto.indices = indices
  proto.reverse = reverse
  proto.arguments = arguments
  proto.template = template
  proto.terms = terms

  function proto:match(pattern, g)
    if (not pattern or proto == pattern) and (not g or g(self)) then
      return self
    end
    for i, v in ipairs(arguments) do
      if self[v[2]] then
        if type(self[v[2]]) == "table" and self[v[2]].match then
          local value = self[v[2]]:match(pattern, g)
          if value ~= nil then
            return value
          end
        end
      end
    end
    return
  end

  function proto:gsub(pattern, f, g)
    -- In-place substitution. Highly recommended to make a :copy() before
    -- calling gsub.
    if (not pattern or proto == pattern) and (not g or g(self)) then
      return f(self, self)
    end
    for i, v in ipairs(arguments) do
      if self[v[2]] then
        if (not pattern or utils.hasmetatable(self[v[2]], pattern)) and
            (not g or g(self[v[2]])) then
          self[v[2]] = f(self[v[2]], self, v[2])
        elseif type(self[v[2]]) == "table" and self[v[2]].gsub then
          self[v[2]] = self[v[2]]:gsub(pattern, f, g)
        end
      end
    end
    return self
  end


  if indices then
    for k, i in pairs(indices) do
      if type(k) == "string" then
        reverse[i] = k
        template[i] = true
        table.insert(arguments, {k, i})
      else
        table.insert(terms, {k, i})
      end
    end

    table.sort(terms, function(a, b)
      return a[1] < b[1]
    end)
    table.sort(arguments, function(a, b)
      return a[2] < b[2]
    end)

    function proto.new(...)
      local self = setmetatable({}, proto)
      for i, v in ipairs(arguments) do
        self[v[2]] = select(i, ...)
      end
      return self
    end

    for i, v in ipairs(terms) do
      -- Reliable cross-version way to find the nil index.
      local j =1
      while true do
        if template[j] == nil then
          break
        end
        j = j + 1
      end
      template[j] = v[2]
    end

    if not __tostring then
      __tostring = function(self)
        local t = ""
        for i, v in ipairs(template) do
          local value = self[i]
          t = t .. (v == true and tostring(value ~= nil and value or "") or v)
        end
        return t
      end
    end

    function proto:__index(index)
      if indices[index] then
        return self[indices[index]]
      end
      return proto[index]
    end

    function proto:__newindex(index, value)
      if indices[index] then
        self[indices[index]] = value
      else
        rawset(self, index, value)
      end
    end

    function proto:repr()
      return self
    end

    function proto:__eq(other)
      return tostring(self) == tostring(other)
    end

    function proto:copy()
      local t = setmetatable({}, proto)
      for i, v in ipairs(arguments) do
        if type(self[i]) == "string" then
          t[v[2]] = self[v[2]]
        elseif self[v[2]] then
          if self[v[2]].copy then
            t[v[2]] = self[v[2]]:copy()
          else
            t[v[2]] = self[v[2]]
          end
        end
      end
      return t
    end
  end
  proto.__tostring = __tostring
  return proto
end

-- Create an identity initializer to be used in function parsers and
-- nonterminals.
-- For now, see leftry/language/lua.lua for usage.
local function id(name, key, __tostring, validate)
  local proto = prototype(name, function(self, value)
    if validate then
      local validated = validate(value)
      if validated ~= nil then
        value = validated
      end
    end
    return setmetatable({value}, self)
  end)

  function proto:__index(index)
    if index == (key or "value") then
      return self[1] or ""
    end
    return proto[index]
  end

  proto.__tostring = __tostring or function(self)
    return tostring(self[1] or "")
  end

  function proto:repr()
    return self
  end

  function proto:gsub(pattern, f, g)
    if (not pattern or proto == pattern) and (not g or g(self)) then
      return f(self, self)
    end
    return self
  end

  function proto:match(pattern, g)
    if (not pattern or proto == pattern) and (not g or g(self)) then
      return self
    end
  end

  function proto:__eq(p)
    return getmetatable(self) == getmetatable(p) and self[1] == p[1]
  end

  function proto:copy()
    return proto(self[1])
  end
  return proto
end


local function const(name, value)
  local constant = {value}
  local proto = prototype(name, function(self)
    return constant
  end)
  setmetatable(constant, proto)
  function proto:__tostring()
    return tostring(value)
  end

  function proto:repr()
    return tostring(getmetatable(self)).."()"
  end

  function proto:gsub(pattern, f, g)
    if (not pattern or proto == pattern) and (not g or g(self)) then
      return f(self, self)
    end
    return self
  end

  function proto:match(pattern, g)
    if (not pattern or proto == pattern) and (not g or g(self)) then
      return self
    end
  end
  return proto
end


-- Create an initializer that casts an array (from `leftflat` or `rightflat`)
-- into this type.
-- For now, see leftry/language/lua.lua for usage.
local function list(name, separator, __tostring, validate)
  local proto = prototype(name, function(self, obj, _, index, rest)
    obj = obj or {}
    obj.n = obj.n or #obj
    if validate then
      local validated = validate(obj)
      if validated ~= nil then
        obj = validated
      end
    end
    obj = setmetatable(obj, self)
    obj.index = index
    obj.rest = rest
    obj.n = obj.n or #obj
    return obj
  end)
  function proto:__index(index)
    if indices and indices[index] then
      return tostring(self[indices[index]])
    end
    return proto[index]
  end

  function proto:repr()
    return self
  end


  function proto:match(pattern, g)
    -- if (not pattern or proto == pattern) and (not g or g(self)) then
    --   return self
    -- end
    for i=1, self.n do
      if (not pattern or utils.hasmetatable(self[i], pattern)) and
          (not g or g(self[i])) then
        return self[i]
      elseif type(self[i]) == "table" and self[i].match then
        local value = self[i]:match(pattern, g)
        if value ~= nil then
          return value
        end
      end
    end
  end

  function proto:gsub(pattern, f, g)
    for i=1, self.n do
      if type(self[i]) == "string" then
        if pattern == "string" then
          self[i] = f(self[i], self, i)
        else
          self[i] = self[i]
        end
      elseif (not pattern or utils.hasmetatable(self[i], pattern)) and
          (not g or g(self[i])) then
        self[i] = f(self[i], self, i)
      elseif type(self[i]) == "table" and self[i].gsub then
        self[i]=self[i]:gsub(pattern, f, g)
      end
    end
    return self
  end

  function proto:copy()
    local t = {n=self.n}
    for i=1, self.n do
      if type(self[i]) == "string" then
        t[i] = self[i]
      else
        if self[i] and self[i].copy then
          t[i] = self[i]:copy()
        else
          t[i] = self[i]
        end
      end
    end

    return proto(t, nil, self.index, self.rest)
  end

  function proto:insert(value)
    self.n = self.n + 1
    self[self.n] = value
    return self
  end

  function proto:__eq(other)
    return tostring(self) == tostring(other)
  end


  function proto:next(i)
    if i < self.n then
      return i + 1, self[i + 1]
    end
  end

  function proto:__ipairs()
    return proto.next, self, 0
  end

  proto.__tostring = __tostring or function(self) return
    table.concat(map(tostring, self, self.n), separator or "")
  end
  return proto
end


return {
  list = list,
  const = const,
  id = id,
  reduce = reduce
}
