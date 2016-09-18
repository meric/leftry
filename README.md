# Leftry - A left recursion enabled recursive-descent parser combinator library. #

This library is for creating and composing parsers.

[Example Lua Parser](http://github.com/meric/l2l/blob/master/l2l/lua.lua#L410)

For example:

```
local grammar = require("leftry")
local factor = grammar.factor
local span = grammar.span

# Declaring a Non-Terminal, "A"
local A = factor("A", function(A) return
  span(A, "1"), # 1st alternative, A := A "1"
  "1"           # 2nd alternative, A := "1"
end)

# Declaring a Non-Terminal, "B"
local B = factor("B", function(B) return
  span(B, "2"), # 1st alternative, B := B "2"
  A             # 2nd alternative, B := A
end)

# Using the composed parser.
# The first argument is the input string.
# The second argument is the string index to start from.
print(B("111122222", 1))
```

This creates a parser `B` that can parse the string "111122222".

The purpose of the anonymous function in declaration of the non-terminal
enables self-reference and referencing other non-terminals that are not fully 
initialized yet.


## Install ##

`luarocks install --server=http://luarocks.org/dev leftry`

## Algorithm ##

First trace with a [left-factored](http://www.csd.uwo.ca/~moreno//CS447/Lectures/Syntax.html/node9.html)
version of the grammar, then apply the left-recursive grammar. Like how a human would intuitively do it.

## Other Top-down left recursion enabled parser combinator implementations ##

* http://hafiz.myweb.cs.uwindsor.ca/xsaiga/fullAg.html
* https://github.com/djspiewak/gll-combinators

## Running unit tests ##

`lua test.lua` 

## Usage ##

* A parser has the following function signature.

 ```
 rest, values = parser(invariant, position, [peek])
 ```

 1. `rest` is the next index to parse. `rest-1` is the last index of the parsed
    value. If `rest` is `nil`, it means the parse is invalid.
 2. `values` is the data created as a result of a successful parse.
 3. `invariant` is the Lua string that is being parsed.
 4. `position` is the integer index to start the parse from.
    It must be 1 or greater.
 5. `peek` (optional). If true, validates only, and `values` will be `nil`.
    Validating without creating the data is several times faster.

* As iterator:

  The function signature of a parser allows it to be used as a Lua iterator
  in a for-loop.

  ```
  local actual = {}
  for rest, values in span("1", "2", "3"), "123123123", 1 do
      table.insert(actual, rest)
  end
  -- actual == {4, 7, 10}
  ```

  This can be useful, for example in a programming language parser, to iterate
  through each parsed statement.

* Composition:

  Parsers can be nested. Left recursion is allowed.

  ```
  local A = factor("A", function(A) return
    span(A, "1"), "1"
  end)
  local B = factor("B", function(B) return
    span(B, "2"), A
  end)
  local src = "11112222"
  assert(B(src, 1, true) == #src + 1)
  ```

* Data initialization:

  You can customise how the data is generated from a parse.

  ```
  local A = factor("A", function(A) return
    span(A, "1") % function(initial, value)
      return (initial or "") .. value
    end, "1"
  end)
  local src = "111"
  A(src, 1) -- returns #src + 1, "111"
  ```

## Left recursion ##

Leftry can handle some examples of left recursion.

* Simple left recursion:

  ```
  local A = factor("A", function(A) return
    span(A, "1"), "1"
  end)
  ```

* Nested left recursion:

  ```
  local A = factor("A", function(A) return
    span(A, "1"), "1"
  end)
  local B = factor("B", function(B) return
    span(B, "2"), A
  end)
  ```

## Performance ##

Performance of the built-in Lua parser.

* Macbook Pro 2.6 Ghz i7 with 16 GB RAM:
  * Lua:
    1. Validate the grammar of around 0.4 megabytes of Lua per second.
    2. Parse 0.1 megabytes of Lua into abstract syntax tree representation per second.
  * LuaJIT:
    1. Validate the grammar of around 4 megabytes of Lua per second.
    2. Parse 0.68 megabytes of Lua into abstract syntax tree representation per second.
  * For comparison:
    1. Lua interpreter can load a 15 megabyte Lua function in one second.
    2. LuaJIT can load a 25 megabyte Lua function in one second.


## Elements ##

* `factor(name, generate, [initializer])`

  Create a non-terminal element.

  * `name` is the tostring value of the element.
  * `generate` is the function that, when called with this element, returns the
    definition of this non-terminal. The values returned with this function
    will be wrapped in an `any`. You may optionally, explicitly return a single
    `any` that contains all the alternatives. Strings literals are
    automatically converted into `term` elements.
  * `initializer` is the function that will be called with values parsed
    from this element to let the user convert the parsed value into something
    useful. See "Data Constructors" section.

  Usage:

  ```
  local A = factor("A", function(A) return
    span(A, "1"), "1"
  end)
  ```

* `rep(element, [reducer])`

  Create a repeating element. It can be used only in an `any` or a `span`.

  * `element` is the element that can appear 0 or more times (if this element
    is in a `span`), or 1 or more times (if this element is in an `any`).
    Strings literals are automatically converted into `term` elements.
  * `reducer` is the function that will be called with values parsed
    from this element to let the user convert the parsed values into something
    useful. See "Data Constructors" section.

  Usage:

  ```
  span(
    "1",
    rep("2", function(a, b) return (a or "")..b end),
    "3")
  ```
* `opt(element)`

  Create an optional element. It can be used only in a `span`.

  * `element` is the element that can appear 0 or 1 times.
    Strings literals are automatically converted into `term` elements.

  Usage:

  ```
  span("1", opt("2"), "3")
  ```

* `any(...)`

  Create an any element. The any element contains a set of alternatives, that 
  will be attempted from left to right.

  The `any` element is used internally to wrap the alternatives returned
  by the `factor` "generate" function.

  You do not need to worry about using `any`.

* `span(...)`

  Create an span element. The span element can be assigned a reducer with the
  `%` operator. See the "Data Constructors" section.

  * `...` the children of the span element. Each child must be encountered in
    order to provide a valid parse, unless it is an `opt` or `rep` element.

  Usage:

  ```
  local A = factor("A", function(A) return
    span(A, "1") % function(initial, value)
      return (initial or "") .. value
    end, "1"
  end)
  ```

  The span element can also be assigned a spacing rule using the `^` operator:

  ```
  local function span(...)
    -- Apply spacing rule to all spans we use in the Lua grammar.
    return grammar.span(...) ^ {spacing=spacing, spaces=" \t\r\n"}
  end
  ```

  See built-in Lua parser for an example on what spacing function looks like.

* `term(literal, [initializer])`

  Create a literal element.

  * `literal` the string literal that must be encountered to provide a valid
    parse.
  * `initializer` is the function that will be called with the literal whenever
    there is a valid parse.

  Usage:

  ```
  term("hello")
  ```

## Data Constructors ##

### Initializer ###

* `factor`

  ```
  function(
      value,    -- The parsed value to transform.
      self,     -- The element responsible for parsing being transformed.
      position, -- The index where `value` was found.
      rest,     -- The next index after `value` ends.
      choice)   -- The index of the alternative `value` was parsed from.

    -- Default implementation
    return value
  end
  ```

* `term`

  ```
  function(
      value,    -- The parsed value to transform. (The literal.)
      self,     -- The element responsible for parsing being transformed.
      position, -- The index where `value` was found.
      rest)     -- The next index after `value` ends.

    -- Default implementation
    return value
  end
  ```

### Reducer ###

Reducers are functions that will be folded over each value that will be parsed.

* `span`

  ```
  function(
    accumulated, -- The accumulated value. In the first iteration it is `nil`.
    value,       -- The current value that is parsed.
    self,        -- The element parsing the current value.
    position,    -- The index where the current value begins.
    rest,        -- The next index after `value` ends.
    i)           -- `value` belongs to the `i`th element of this `span` element.

    -- Default implementation
    return rawset(initial or {}, i, value)
  end
  ```

* `rep`

  ```
  function(
    accumulated, -- The accumulated value. In the first iteration it is `nil`.
    value,       -- The current value that is parsed.
    self,        -- The element parsing the current value.
    position,    -- The index where the current value begins.
    rest,        -- The next index after `value` ends.
    i)           -- The `i`th time the child element has been encountered.

    -- Default implementation
    return rawset(initial or {}, i, value)
  end
  ```

## Caveats ##

The current implementation does not enforce the following rules properly.

1. A `span` must have more than one child.
2. In a left recursion alternative, only the first element may be the
   left-recurring non-terminal. More than one consecutive left-recurring
   non-terminal is not supported, even if it currently works.

   ```
   -- This is OK
   local A = factor("A", function(A) return
                span(A, "1", A, "2"), "1"
             end)
   -- This is not OK
   local A = factor("A", function(A) return
                span(A,  A, "1", "2"), "1"
             end)
   ```
3. An `any` element must not have any `opt` children.
4. A `rep` element that is a child of an `any` element requires 1 or more
   elements to match.
5. A `rep` element that is a child of an `span` element requires 0 or more
   elements to match.
6. The first nonterminal element of a span that is part of a left recursion
   path, cannot be wrapped in `opt` or `rep`.

## TODO ##

* ~~Implement Lua grammar in Leftry to prove it can handle the grammar of a
programming language.~~
* ~~Implement whitespacing support.~~
* ~~Add appropriate data initializers for the builtin Lua parser, to override the
  default ones.~~

* Test the following grammar:

    ```
    "b"
    | s ~ s       ^^ { _ + _ }
    | s ~ s ~ s   ^^ { _ + _ + _ }
    https://github.com/djspiewak/gll-combinators
    ```
