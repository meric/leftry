return function()
  local t = {}
  for i=1, 255 do
    table.insert(t, i)
  end
  return unpack(t)
end