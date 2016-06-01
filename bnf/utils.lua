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

local function dotmap(f, ...)
  if select("#", ...) > 0 then
    return f(select(1, ...)), dotmap(f, select(2, ...))
  end
end

local function map(f, t)
  local u = {}
  for i=1, #t do
    u[i]=f(t[i])
  end
  return u
end

local function copy(t)
  local u = {}
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
  table.sort(k)
  return k
end

local function torepresentation(callable, arguments)
  return string.format("%s(%s)", tostring(callable),
    table.concat(map(tostring, arguments), ","))
end

return {
    prototype=prototype,
    dotmap=dotmap,
    map=map,
    torepresentation=torepresentation,
    keys=keys,
    trait=trait,
    copy=copy
}
