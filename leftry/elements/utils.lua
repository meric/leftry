local term = require("leftry.elements.term")

local termize = function(value)
  if type(value) == "string" then
    return term(value)
  end
  return value
end

local invariantize = function(value)
  if type(value) == "string" then
    return {source=value, events={}}
  end
  return value
end

return {
  termize=termize,
  invariantize=invariantize
}
