local nth = function(j)
  return function(a, b, i)
    if i == j then
      return b
    end
    return a
  end
end

local first = nth(1)
local second = nth(2)

local concat = function(a, b, i)
  if not a then
    return tostring(b)
  end
  return tostring(a) .. tostring(b)
end

return {
  nth = nth,
  first = first,
  second = second,
  concat = concat
}
