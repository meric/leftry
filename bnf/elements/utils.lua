local term = require("bnf.elements.term")

local termize = function(value)
  if type(value) == "string" then
    return term(value)
  end
  return value
end

return {
  termize=termize
}
