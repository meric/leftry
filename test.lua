local utils = require("bnf").utils
local grammar = require("bnf").grammar
local lua = require("bnf.language.lua")
local traits = require("bnf.elements.traits")
local span = grammar.span
local opt = grammar.opt
local rep = grammar.rep
local any = grammar.any
local factor = grammar.factor
local tests = {}

function tests.dotmap()
  return {utils.dotmap(function(x) return x + 1 end, 1, 3, 5)}, {2, 4, 6}
end

function tests.map()
  return utils.map(function(x) return x * 2 end, {1, 3, 5}), {2, 6, 10}
end

function tests.torepresentation()
  return {utils.torepresentation("dotmap", {1, 2, 3})}, {"dotmap(1,2,3)"}
end

function tests.factor_peek_parse_success()
  local A = factor("A", function(A) return
    span(A, "1"), "1"
  end)
  local src = "11"
  return {A({src=src}, 1, nil, true)}, {#src + 1}
end

function tests.factor_parse_success()
  local A = factor("A", function(A) return
    span(A, "1") % function(initial, value)
      return (initial or "") .. value
    end, "1"
  end)
  local src = "111"
  return {A({src=src}, 1)}, {#src + 1, "111"}
end

function tests.factor_first_third_parse_success()
  local A = factor("A", function(A) return
    span(A, "2", A, "3") % function(initial, value)
      return (initial or "") .. value
    end, "1"
  end)
  local src = "1213"
  return {A({src=src}, 1)}, {#src + 1, "1213"}
end

function tests.factor_first_second_parse_success()
  local A = factor("A", function(A) return
    span(A, A, "3") % function(initial, value)
      return (initial or "") .. value
    end, "1"
  end)
  local src = "113"
  return {A({src=src}, 1)}, {#src + 1, "113"}
end

function tests.factor_nested_parse_success()
  local A = factor("A", function(A) return
    span(A, "1"), "1"
  end)
  local B = factor("B", function(B) return
    span(B, "2"), A
  end)
  local src = "11112222"
  return {B({src=src}, 1, nil, true)}, {#src + 1}
end

function tests.span_opt_parse_success()
  local src = "13"
  local rest, values = span("1", opt("2"), "3")({src=src}, 1)
  return {rest, values[1], values[3]}, {#src + 1, "1", "3"}
end

function tests.span_rep_parse_success()
  local src = "13"
  local rest, values = span("1", rep("2"), "3")({src=src}, 1)
  return {rest, values[1], values[3]}, {#src + 1, "1", "3"}
end

function tests.span_rep1_parse_success()
  local src = "122223"
  local rest, values =
    span(
      "1",
      rep("2", function(a, b) return (a or "")..b end),
      "3")({src=src}, 1)
  return {rest, unpack(values or {})}, {#src + 1, "1", "2222", "3"}
end

function tests.span_parse_success()
  local src = "123"
  local rest, values = span("1", "2", "3")({src=src}, 1)
  return {rest, unpack(values or {})}, {#src + 1, "1", "2", "3"}
end

function tests.span_parse_failure()
  local src = "1"
  local rest, values = span("1", "2", "3")({src=src}, 1)
  return {rest, unpack(values or {})}, {nil, nil}
end

function tests.span_as_iterator()
  local src = "123123123"
  local actual = {}
  for i, values in span("1", "2", "3"), {src=src}, 1 do
    table.insert(actual, i)
  end
  return actual, {4, 7, 10}
end

function tests.any_parse_success()
  local src = "123"
  local rest, value = any("1", "2", "3")({src=src}, 1)
  return {rest, value}, {2, "1"}
end

function tests.any_parse_failure()
  local src = "4123"
  local rest, value = any("1", "2", "3")({src=src}, 1)
  return {rest, value}, {nil, nil}
end

function tests.any_as_iterator()
  local src = "123123123"
  local actual = {}
  for i, values in any("1", "2", "3"), {src=src}, 1 do
    table.insert(actual, i)
  end
  return actual, {2, 3, 4, 5, 6, 7, 8, 9, 10}
end

function tests.lua_string_parse_success()
  local src = '"hello world!"'
  local rest, values = lua.LiteralString({src=src}, 1)
  return {rest, unpack(values or {})}, {#src + 1, '"', "hello world!", '"'}
end

function tests.lua_exp_parse_success()
  local src = '"hello world!"'
  local rest, values = lua.Exp({src=src}, 1)
  return {rest, unpack(values or {})}, {#src + 1, '"', "hello world!", '"'}
end

function tests.lua_exp1_parse_success()
  local src = '1+1'
  local rest, values = lua.Exp({src=src}, 1)
  return {rest, unpack(values or {})}, {#src + 1, 1, "+", 1}
end

function tests.lua_var_parse_success()
  local src = 'print'
  local rest, values = lua.Var({src=src}, 1)
  return {rest, values}, {#src + 1, "print"}
end

function tests.lua_prefixexp_parse_success()
  local src = 'print'
  local rest, values = lua.PrefixExp({src=src}, 1)
  return {rest, values}, {#src + 1, "print"}
end

function tests.lua_args_parse_success()
  local src = '(1)'
  local rest, values = lua.PrefixExp({src=src}, 1)
  return {rest, unpack(values or {})}, {#src + 1, "(", 1, ")"}
end

function tests.lua_args2_parse_success()
  local src = '()'
  local rest, values = lua.Args({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_functioncall0_parse_success()
  local src = 'print(1)'
  local rest, values = lua.FunctionCall(
    {src=src}, 1, nil, true)
  return {rest}, {#src + 1}
end

function tests.lua_functioncall_parse_success()
  local src = 'print(1)'
  local rest, values = lua.FunctionCall({src=src}, 1, nil)
  return {rest, values[1], values[2][1], values[2][2][1], values[2][3]},
    {#src + 1, "print", "(", 1, ")"}
end

function tests.lua_functioncall2_parse_success()
  local src = 'a()()'
  local rest, values = lua.FunctionCall({src=src}, 1, nil)
  return {rest}, {#src+1}
  -- return {rest, values[1][1], values[1][2][1], values[1][2][3], values[2][1],
  --   values[2][3]}, {#src + 1, "a", "(", ")", "(", ")"}
end

function tests.lua_retstat_parse_success()
  local src = 'return (1+1)'
  local rest, values = lua.RetStat({src=src}, 1, nil, true)
  return {rest, unpack(values or {})}, {#src + 1}
end

function tests.lua_retstat_parse_failure()
  local src = 'returntrue'
  return {lua.RetStat({src=src}, 1, nil, true)}, {nil}
end

function tests.lua_block_parse_success()
  local src = 'print(1);return true'
  lua.Block:setup()
  local rest, values = lua.Block({src=src}, 1, nil, true)
  return {rest, unpack(values or {})}, {#src + 1}
end

function tests.lua_var_parse_failure()
  local src = 'a()'
  local rest, values = lua.Var({src=src}, 1, nil)
  return {rest}, {2}
end

function tests.lua_search_nonterminal_binop()
  lua.BinOp:setup()
  return {traits.search_left_nonterminal(lua.BinOp.canonize(),
    lua.BinOp)}, {false}
end

function tests.lua_exp()
  local src = 'b()'
  local rest, values = lua.PrefixExp({src=src}, 1, nil, true)
  return {rest}, {#src + 1}
end

function tests.lua_stat()
  local src = 'local utils = require("bnf").utils'
  local rest, values = lua.Stat({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_block()
  local src = [[
    local utils = require("bnf").utils
    local grammar = require("bnf").grammar
  ]]
  local rest, values = lua.Block({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_table()
  local src = 'local test = {}'
  local rest, values = lua.Stat({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_function()
  local src =[[function(x) return x end]]
  local rest, values = lua.Exp({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_function1()
  local src =[[return {function(x) return x + 1 end}]]
  local rest, values = lua.RetStat({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_function2()
  local src =[[a.b()]]
  local rest, values = lua.Exp({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_length()
  local src =[[#src]]
  local rest, values = lua.Exp({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_big_for()
  local src = [[
  for _, name in ipairs(utils.keys(tests)) do
    if not arg[1] or arg[1] == name then
      local test = tests[name]
      io.write(("test (%s)"):format(name))
      local passed, n = compare(test())
      if passed then
        io.write(("...%s ok\n"):format(n))
        passes = passes + 1
      else
        io.write(("...%s total\n"):format(n))
        fails = fails + 1
      end
    end
  end
  ]]
  local rest, values = lua.Stat({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_big_function()
  local src = [[
    Comment = factor("Comment", function() return
      grammar.span("--", function(invariant, position)
        while invariant.src:sub(position, position) ~= "\n" do
          position = position + 1
        end
        return position
      end) end)
  ]]
  local rest, values = lua.Stat({src=src}, 1, nil)
  return {rest}, {#src + 1}
end

function tests.lua_function3()
  local src = [[a.b.c()]]
  local rest, values = lua.PrefixExp({src=src}, 1, nil)
  return {rest}, {#src + 1}
end


function tests.lua_var()
  local src = [[a.b.c]]
  local rest, values = lua.Var({src=src}, 1, #src + 1)
  return {rest}, {#src + 1}
end

function tests.lua_var0()
  local src = [[a.b.c]]
  lua.PrefixExp:setup()
  local rest, values = lua.PrefixExp.canon({src=src}, 1, 2, true)
  return {rest}, {2}
end


function tests.lua_big_parse()
  local f = io.open("test.lua")
  local invariant = {src=f:read("*all")}
  -- invariant.src = invariant.src:rep(20)
  f.close()

  local rest = lua.Chunk(invariant, 1, nil)

  -- print(invariant.src:sub(rest, rest+100))
  return {rest}, {#invariant.src + 1}
end

function tests.lua_big_parse2()
  local f = io.open("bnf/language/lua.lua")
  local invariant = {src=f:read("*all")}
  f.close()

  local rest = lua.Chunk(invariant, 1, nil, true)

  -- print(invariant.src:sub(rest, rest+100))
  return {rest}, {#invariant.src + 1}
end

local function compare(actual, expected)
  assert(actual) assert(expected)
  local passed = true
  for i=1, math.max(table.maxn(actual), table.maxn(expected)) do
    local value = actual[i]
    if value == expected[i] then
      -- print(("  passed %s == %s"):format(
      --   tostring(value),
      --   tostring(expected[i])))
    else
      print(("\n  failed %s == %s"):format(
        tostring(value),
        tostring(expected[i])))
      passed = false
    end
  end
  return passed, #expected
end

local passed = true
local passes, fails = 0, 0
for _, name in ipairs(utils.keys(tests)) do
  if not arg[1] or arg[1] == name then
    local test = tests[name]
    io.write(("test (%s)"):format(name))
    local passed, n = compare(test())
    if passed then
      io.write(("...%s ok\n"):format(n))
      passes = passes + 1
    else
      io.write(("...%s total\n"):format(n))
      fails = fails + 1
    end
  end
end

print(("\n%s tests, %s passes, %s fails"):format(passes+fails, passes,fails))
