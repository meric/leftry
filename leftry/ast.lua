local utils = require("leftry.utils")
local prototype = utils.prototype
local map = utils.map


local function reduce(name, indices, __tostring)
  local reverse = {}
  local template = {}
  local terms = {}
  local proto = prototype(name, function(self, values, value, i, _, index, rest)
    if not values then
      values = setmetatable({index=index, rest=rest}, self)
    end
    if not indices or reverse[i] then
      values[i] = value
    end
    -- if name == "lua_assign" and i==3 then
    --   print(values)
    -- end
    values.rest = rest
    return values
  end)
  if indices then
    for k, i in pairs(indices) do
      if type(k) == "string" then
        reverse[i] = k
        template[i] = true
      else
        table.insert(terms, {k, i})
      end
    end

    table.sort(terms, function(a, b)
      return a[1] < b[1]
    end)

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
    end
  end
  proto.__tostring = __tostring
  return proto
end

local function id(name, key, __tostring)
  local proto = prototype(name, function(self, value)
    return setmetatable({value}, self)
  end)
  function proto:__index(index)
    if index == (key or "value") then
      return self[1] or ""
    end
  end
  proto.__tostring = __tostring or function(self)
    return tostring(self[1] or "")
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
  return proto
end

local function cast(name, separator, indices, __tostring)
  local reverse = {}
  if indices then
    for k, i in pairs(indices) do
      reverse[i] = k
    end
  end
  local proto = prototype(name, function(self, obj, _, index, rest)
    obj = setmetatable(obj, self)
    obj.index = index
    obj.rest = rest
    return obj
  end)
  function proto:__index(index)
    if indices and indices[index] then
      return tostring(self[indices[index]])
    end
  end
  proto.__tostring = __tostring or function(self) return
    table.concat(map(tostring, self), separator or "")
  end
  return proto
end


return {
  cast = cast,
  const = const,
  id = id,
  reduce = reduce
}
