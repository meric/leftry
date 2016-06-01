# BNF.lua - A recursive-descent left recurrable parser combinator library. #

This is alpha software.

## TODO ##

Implement Lua grammar in BNF.lua to prove it can handle the grammar of a
programming language.

## Left recursion ##

BNF.lua can handle some examples of left recursion.

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

## Unit tests ##

`lua test.lua` 

## Elements ##

* `factor(name, generate, [initializer])`

  Create a non-terminal element.

  * `name` is the tostring value of the element.
  * `generate` is the function that, when called with itself, returns the
    definition of this non-terminal. The values returned with this function
    will be wrapped in an `any`. You may optionally, explicitly return a single
    `any` that contains all the alternatives. Strings literals are
    automatically converted into `term` elements.
  * `initializer` is the function that will be called with values parsed
    from this element to let the user convert the parsed value into something
    useful. See "Constructors" section.

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
    useful. See "Constructors" section.

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

* `span(...)`

  Create an span element. The span element can be assigned a reducer with the
  `%` operator. See the "Constructors" section.

  * `...` the children of the span element. Each child must be encountered in
    order to provide a valid parse (unless it is an `opt` or `rep` element),

  Usage:

  ```
  local A = factor("A", function(A) return
    span(A, "1") % function(initial, value)
      return (initial or "") .. value
    end, "1"
  end)
  ```

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

## Constructors ##

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
   left-recurring non-terminal. There cannot be more than one consecutive
   left-recurring non-terminal.

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
