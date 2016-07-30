local function id(value)
  return value
end

local function none()
  return
end

local function metatable(mt)
  return function(value)
    return setmetatable(value, mt)
  end
end

local function leftflat(values, value)
  if not values then
    return value or {}
  end
  if value ~= nil then
    values.n = math.max(#values, values.n or 0) + 1
  end
  return rawset(values, #values + 1, value)
end

local function rightflat(values, value, i, self)
  if i == 1 then
    values = {}
  end
  if i < #self then
    return rawset(values, #values + 1, value)
  elseif value then
    for i, v in ipairs(value) do
      rawset(values, #values + 1, v)
    end
  end
  return values
end

return {
  id=id,
  leftflat=leftflat,
  rightflat=rightflat,
  none=none,
  metatable=metatable
}