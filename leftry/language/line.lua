return function()
  return {
    Line = function(invariant, position, peek)
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
  }
end
