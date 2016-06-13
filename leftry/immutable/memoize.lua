local reverse = require("leftry.utils").reverse

local function curry(f, n, ...)
  local curried = {...}
  if n > 1 then
    return function(self, a)
      local u = setmetatable({}, { __mode='k', __index = curry(f, n-1, a,
        unpack(curried)) })
      self[a] = u
      return u
    end
  else
    local parameters = reverse(curried)
    return function(self, a)
      table.insert(parameters, a)
      local u = f(unpack(parameters))
      self[a] = u
      return u
    end
  end
end

local cache_memoize = setmetatable({}, {__mode='k', __index=curry(
  function(f, n)
    return setmetatable({}, {__mode='k', __index=curry(f, n)})
  end, 2)})

local function memoize(f, n)
  return cache_memoize[f][n]
end

return memoize
