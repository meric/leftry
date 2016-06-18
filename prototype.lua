local grammar = require("leftry").grammar
local factor = grammar.factor
local span = grammar.span

local set = require("leftry.immutable.set")
local set_insert, set_empty = set.insert, set.empty

-- prototype of an example of a statically compiled leftry grammar.

local A = factor("A", function(A) return
  span(A, "1"), "1"
end)
local B = factor("B", function(B) return
  span(B, "2"), A
end)

-- P == B

local one = "1"
local two = "2"

local function P(invariant, position, peek)
  if position > #invariant then
    return
  end

  local rest

  if not rest then
    if invariant:sub(position, position + #(one) - 1) == one then
      rest = position + #(one)
    end
  end
  if not rest then
    return
  end

  local done = rest

  while rest and #invariant >= rest do
    local index = rest
    -- if not met[t] then
      if index <= #invariant then
        -- span
        if invariant:sub(index, index + #(one) - 1) == one then
          rest = index + #(one)
          done = rest
        else
          rest = nil
        end
      end
    -- end
  end
  rest = done

  local done = rest

  while rest and #invariant >= rest do
    local index = rest
    -- if not met[t] then
      if index <= #invariant then
        -- span
        if invariant:sub(index, index + #(two) - 1) == two then
          rest = index + #(two)
          done = rest
        else
          rest = nil
        end
      end
    -- end
  end
  rest = done

  return rest
end

print(P(("11112222"), 1))

