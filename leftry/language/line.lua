local function Line(invariant, position, peek)
  if position > #invariant then
    return
  end

  local rest = string.find(invariant, "\n", position + 1) or #invariant + 1
  local value

  if rest and not peek then
    value = invariant:sub(position+1, rest-1)
  end
  return rest, value
end

local index = setmetatable({}, {
  __index = function(self, invariant)
    self[invariant] = {}
    local n = 0
    local i = 1
    for rest, line in Line, invariant, i do
      n = n + 1
      self[invariant][n] = i
      i = rest
    end
    return self[invariant]
  end
})

return {
  index = index,
  Line = Line
}
