# Leftry - A left recursion enabled recursive-descent parser combinator library. #

Humans can parse a left recursion grammar without stack overflowing.

Computers ought to be able to, too!

This is alpha software.

## How ##

> It's clear that recursive descent parser will go into infinite loop if 
 the non-terminal keeps on expanding into itself.
> - [A Stack Overflow User](http://stackoverflow.com/a/30375377)

When we look at a grammar and parse it with our eyes, it feels natural to
use recursive descent. When we encounter instances of left recursion, our
eyes are able to look ahead and rewrite the grammar, see how far the left
recursions go, and then piece the left recursions back together. Why can't
a recursive descent algorithm do the same thing?

*Have you ever seen a computer science student stuck in class, because he can't get out of a left
recursive parse?*

> To adapt this grammar to use with a recursive descent parser, we need to eliminate the left recursion.
> - [A lecturer at a university](http://faculty.ycp.edu/~dhovemey/fall2011/cs340/lecture/lecture9.html)

So you're saying we have to rewrite the grammar *by hand*, and then we have to
twist our data functions this way and that way to rebuild our
original intention with this grammar? Left recursion is feels so natural to
use when writing certain grammars!

> For recursive descent, left recursion must be avoided at all costs
> - [Another Stack Overflow User](http://cs.stackexchange.com/questions/2696/left-recursion-and-left-factoring-which-one-goes-first#comment7246_2696)

You're not listening to me. Why should *I* be the one have to rewrite my
grammar, and twist my data functions to support this?

*I paid $2000 for this Macbook Pro.*

*Why can't the computer do it?*

> Your time is limited, so don't waste it living someone else's life.
  Don't be trapped by dogma - which is living with the results of other
  people's thinking. Don't let the noise of other's opinions drown out your own
  inner voice. And most important, have the courage to follow your heart and
  intuition. They somehow already know what you truly want to become.
  Everything else is secondary.
> - [Steve Jobs](https://news.stanford.edu/2005/06/14/jobs-061505/)

&nbsp;

> Here goes...
> - Me, December 2015

&nbsp;

> I think it's getting there. Hmm, what month is this?
> - Me, June 2016

## Lua Parser ##

[Lua parser implemented in Leftry](leftry/language/lua.lua#L134)

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
    2. Parse 0.18 megabytes of Lua into tables per second.
  * LuaJIT:
    1. Validate the grammar of around 4 megabytes of Lua per second.
    2. Parse 1 megabytes of Lua into tables per second.
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
* Add appropriate data initializers for the builtin Lua parser, to override the
  default ones.
