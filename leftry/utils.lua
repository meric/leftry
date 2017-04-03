local __ipairs = ipairs

local ipairs = ipairs

local function len(t)
  if not t then
    return 0
  end
  return #t
end

if ipairs(setmetatable({}, {__ipairs=function() end})) == ipairs({}) then
  ipairs = function(t)
    local mt = getmetatable(t)
    if not mt or not mt.__ipairs then
      return __ipairs(t)
    end
    return mt.__ipairs(t)
  end
end

if #setmetatable({}, {__len=function() return 5 end}) == 0 then
  len = function(t)
    if not t then
      return 0
    end
    local mt = getmetatable(t)
    if not mt or not mt.__len then
      return #t
    end
    return mt.__len(t)
  end
end

local function prototype(name, initializer)
  local self = setmetatable({}, {
    __tostring = function(self)
      return name
    end,
    __call = initializer
  })
  self.__index = self
  return self
end

local function hasmetatable(value, mt)
  return getmetatable(value) == mt
end

local function dotmap(f, ...)
  if select("#", ...) > 0 then
    return f(select(1, ...)), dotmap(f, select(2, ...))
  end
end

local function escape(text)
  return "\""..text
    :gsub("\\", "\\\\")
    :gsub("\"", "\\\"")
    :gsub("\n", "\\n").."\""
end

local function inserts(f, t, n)
  local u = {}
  for i, v in ipairs(t) do
    table.insert(u, f(v, i, u))
  end
  return u
end

local function map(f, t, n)
  local u = {}
  for i=1, n or len(t) do
    u[i]=f(t[i], i)
  end
  return u
end

local function each(f, t)
  local u = {}
  for k, v in pairs(t) do
    u[k]=f(v, k)
  end
  return u
end

local function filter(f, t, n)
  local u = {}
  for i=1, n or len(t) do
    local x = t[i]
    if f(x) then
      table.insert(u, x)
    end
  end
  return u
end

local function contains(t, u, n)
  for i=1, n or len(t) do
    if t[i] == u then
      return true
    end
  end
end

function reverse(t)
  local u = {}
  for k, v in ipairs(t) do
      u[len(t) + 1 - k] = v
  end
  return u
end

local function copy(t, u)
  u = u or {}
  for k, v in pairs(t) do
    u[k] = v
  end
  return u
end

local function keys(t)
  local k = {}
  for key, _ in pairs(t) do
    table.insert(k, key)
  end
  table.sort(k, function(a, b)
    return tostring(a) < tostring(b)
  end)
  return k
end

local function torepresentation(callable, arguments)
  return string.format("%s(%s)", tostring(callable),
    table.concat(map(tostring, arguments), ","))
end

local function compose(a, ...)
  if not ... then
    return a
  end
  local functions = {...}
  return function(...)
    local returns = table.pack(a(...))
    for i, fun in ipairs(functions) do
      if not (returns[1] ~= nil or returns.n > 1) then
        break
      end
      returns = table.pack(fun(table.unpack(returns, returns.n)))
    end
    return table.unpack(returns, returns.n)
  end
end

return {
  prototype=prototype,
  ipairs = ipairs,
  len=len,
  dotmap=dotmap,
  inserts=inserts,
  map=map,
  filter=filter,
  torepresentation=torepresentation,
  keys=keys,
  copy=copy,
  contains=contains,
  reverse=reverse,
  each=each,
  escape=escape,
  hasmetatable=hasmetatable,
  compose=compose
}
