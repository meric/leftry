local prototype = require("leftry.utils").prototype

local trait = prototype("trait", function(trait, name, memoize_n)
  return setmetatable({name=name, memoize={}}, trait)
end)

function trait:__tostring()
  return self.name
end

function trait:where(mt, impl, n)
  if n then
    if n < 1 or n > 2 then
      error("can only memoize one or two arguments. not ".. tostring(n))
    end
    rawset(self.memoize, mt, n)
  end
  return rawset(self, mt, impl)
end

function trait:__call(this, ...)
  local t = type(this)
  if self[t] then
    return self[t](this, ...)
  end
  local mt = getmetatable(this)
  if self[mt] then
    local n = self.memoize[mt]
    local i = select("#", ...)
    if n == 1 and i == 0 then
      local attr = "_"..self.name
      local cache = this[attr]
      if cache ~= nil then
        return cache
      end
      rawset(this, attr, self[mt](this, ...))
      return this[attr]
    elseif n == 2 and i == 1 then
      local attr = "_"..self.name
      local cache = this[attr] or rawset(this, attr, {})
      local param = ...
      local value = cache[param]
      if value ~= nil then
        return value
      end
      rawset(cache, param, self[mt](this, ...))
      return cache[param]
    end
    return self[mt](this, ...)
  end
  error(tostring(self).." not implemented for: ".. tostring(this)..
      " :: ".. tostring(getmetatable(this) or "")..", "..type(this))
end

return trait
