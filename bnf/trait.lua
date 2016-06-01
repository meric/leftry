local prototype = require("bnf.utils").prototype

local trait = prototype("trait", function(self, name)
  return setmetatable({name=name}, self)
end)

function trait:__tostring()
  return self.name
end

function trait:where(mt, impl)
  return rawset(self, mt, impl)
end

function trait:__call(this, ...)
  local t = type(this)
  if self[t] then
    return self[t](this, ...)
  end
  local mt = getmetatable(this)
  if self[mt] then
    return self[mt](this, ...)
  end
  error(tostring(self).." not implemented for: ".. tostring(this)..
      " :: ".. tostring(getmetatable(this) or type(this)))
end

return trait
