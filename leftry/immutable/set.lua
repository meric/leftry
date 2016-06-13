--[[--
Immutable Set

Only use `insert` and `remove` to add or remove objects from sets.

There can only be one immutable set for a particular set of content objects.
--]]--

local utils = require("leftry.utils")
local copy = utils.copy

local cache_remove = setmetatable({}, {
  __mode='k',
  __index=function(self, s)
    local t = setmetatable({}, {__mode='k'})
    rawset(self, s, t)
    return t
  end
})

local cache_insert = setmetatable({}, {
  __mode='k',
  __index=function(self, s)
    local t = setmetatable({}, {__mode='k',
      __index=function(cache, x)
        local u = rawset(copy(s), x, true)
        cache_remove[u][x] = s
        cache[x] = u
        return u
      end})
    rawset(self, s, t)
    return t
  end
})

-- The empty set.
local empty = {}

local function id(s)
  if s then
    return s
  end
  return empty
end

local function insert(s, x)
  if s[x] then
    return s
  end
  return cache_insert[s][x]
end

local function remove(s, x)
  if not s[x] then
    return s
  end
  return cache_remove[s][x]
end

return {
  id=id,
  insert=insert,
  remove=remove,
  empty=empty
}
