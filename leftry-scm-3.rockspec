package = "Leftry"
version = "scm-3"
source = {
  url = "git://github.com/meric/leftry"
}
description = {
  summary = "A left recursion enabled recursive-descent parser combinator library.",
  detailed = [[
    This library is for creating and composing parsers.

    For example:

    ```
    local grammar = require("leftry")
    local factor = grammar.factor
    local span = grammar.span
    local A = factor("A", function(A) return
      span(A, "1"), "1"
    end)
    local B = factor("B", function(B) return
      span(B, "2"), A
    end)
    print(B("111122222", 1))
    ```

    This creates a parser `B` that can parse the string "111122222".
  ]],
  homepage = "http://github.com/meric/leftry",
  license = "MIT/X11"
}
dependencies = {
  "lua >= 5.2"
}
build = {
  type = "builtin",
  modules = {
    ["leftry"]="leftry.lua",
    ["leftry.elements.any"]="leftry/elements/any.lua",
    ["leftry.elements.factor"]="leftry/elements/factor.lua",
    ["leftry.elements.opt"]="leftry/elements/opt.lua",
    ["leftry.elements.rep"]="leftry/elements/rep.lua",
    ["leftry.elements.span"]="leftry/elements/span.lua",
    ["leftry.elements.term"]="leftry/elements/term.lua",
    ["leftry.elements.traits"]="leftry/elements/traits.lua",
    ["leftry.elements.traits.hash"]="leftry/elements/traits/hash.lua",
    ["leftry.elements.traits.left_nonterminals"]="leftry/elements/traits/left_nonterminals.lua",
    ["leftry.elements.traits.search_left_nonterminal"]="leftry/elements/traits/search_left_nonterminal.lua",
    ["leftry.elements.traits.search_left_nonterminals"]="leftry/elements/traits/search_left_nonterminals.lua",
    ["leftry.elements.utils"]="leftry/elements/utils.lua",
    ["leftry.immutable.memoize"]="leftry/immutable/memoize.lua",
    ["leftry.immutable.set"]="leftry/immutable/set.lua",
    ["leftry.language.lua"]="leftry/language/lua.lua",
    ["leftry.grammar"]="leftry/grammar.lua",
    ["leftry.trait"]="leftry/trait.lua",
    ["leftry.utils"]="leftry/utils.lua",
    ["leftry.ast"]="leftry/ast.lua",
    ["leftry.reducers"]="leftry/reducers.lua",
    ["leftry.initializers"]="leftry/initializers.lua",
  }
}
