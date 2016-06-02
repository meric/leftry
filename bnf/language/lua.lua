local grammar = require("bnf.grammar")

local span = grammar.span
local opt = grammar.opt
local rep = grammar.rep
local factor = grammar.factor

-- Lua Grammar
-- chunk ::= block
-- block ::= {stat} [retstat]
-- stat ::=  ‘;’ | 
--      varlist ‘=’ explist | 
--      functioncall | 
--      label | 
--      break | 
--      goto Name | 
--      do block end | 
--      while exp do block end | 
--      repeat block until exp | 
--      if exp then block {elseif exp then block} [else block] end | 
--      for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end | 
--      for namelist in explist do block end | 
--      function funcname funcbody | 
--      local function Name funcbody | 
--      local namelist [‘=’ explist] 

-- retstat ::= return [explist] [‘;’]
-- label ::= ‘::’ Name ‘::’
-- funcname ::= Name {‘.’ Name} [‘:’ Name]
-- varlist ::= var {‘,’ var}
-- var ::=  Name | prefixexp ‘[’ exp ‘]’ | prefixexp ‘.’ Name 
-- namelist ::= Name {‘,’ Name}
-- explist ::= exp {‘,’ exp}
-- exp ::=  nil | false | true | Numeral | LiteralString | ‘...’ | functiondef | 
--      prefixexp | tableconstructor | exp binop exp | unop exp 
-- prefixexp ::= var | functioncall | ‘(’ exp ‘)’
-- functioncall ::=  prefixexp args | prefixexp ‘:’ Name args 
-- args ::=  ‘(’ [explist] ‘)’ | tableconstructor | LiteralString 
-- functiondef ::= function funcbody
-- funcbody ::= ‘(’ [parlist] ‘)’ block end
-- parlist ::= namelist [‘,’ ‘...’] | ‘...’
-- tableconstructor ::= ‘{’ [fieldlist] ‘}’
-- fieldlist ::= field {fieldsep field} [fieldsep]
-- field ::= ‘[’ exp ‘]’ ‘=’ exp | Name ‘=’ exp | exp
-- fieldsep ::= ‘,’ | ‘;’
-- binop ::=  ‘+’ | ‘-’ | ‘*’ | ‘/’ | ‘//’ | ‘^’ | ‘%’ | 
--      ‘&’ | ‘~’ | ‘|’ | ‘>>’ | ‘<<’ | ‘..’ | 
--      ‘<’ | ‘<=’ | ‘>’ | ‘>=’ | ‘==’ | ‘~=’ | 
--      and | or
-- unop ::= ‘-’ | not | ‘#’ | ‘~’

-- Non-Terminals

local Chunk, Block, Stat, RetStat, Label, FuncName, VarList, Var, NameList,
      ExpList, Exp, PrefixExp, FunctionCall, Args, FunctionDef, FuncBody,
      ParList, TableConstructor, FieldList, Field, FieldSep, BinOp, UnOp,
      Numeral, LiteralString, Name

local dquoted, squoted

Chunk = factor("Chunk", function() return
  Block end)
Block = factor("Block", function() return
  span(rep(Stat), opt(RetStat)) end)
Stat = factor("Stat", function() return
  span(VarList, "=", ExpList),
  FunctionCall,
  Label,
  "break",
  span("goto", Name),
  span("do", Block, "end"),
  span("while", Exp, "do", Block, "end"),
  span("repeat", Block, "until", Exp),
  span("if", Exp, "then", Block, rep(span("elseif", Exp, "then", Block)),
    opt(span("else", Block), "end")),
  span("for", Name, "=", Exp, ",", Exp, opt(span(",", Exp)), "do", Block,
    "end"),
  span("for", NameList, "in", ExpList, "do", Block, "end"),
  span("function", FuncName, FuncBody),
  span("local", "function", Name, FuncBody),
  span("local", NameList, opt(span("=", ExpList))) end)
RetStat = factor("RetStat", function() return
  span("return", opt(ExpList), opt(";")) end)
Label = factor("Label", function() return
  span("::", Name, "::") end)
FuncName = factor("FuncName", function() return
  span(Name, rep(span(".", Name)), opt(span(":", Name))) end)
VarList = factor("VarList", function() return
  span(Var, rep(span(",", Var))) end)
Var = factor("Var", function() return
  Name, span(PrefixExp, "[", Exp, "]"), span(PrefixExp, ".", Name) end)
NameList = factor("NameList", function() return
  span(Name, rep(span(",", Name))) end)
ExpList = factor("ExpList", function() return
  span(Exp, rep(span(",", Exp))) end)
Exp = factor("Exp", function(Exp) return
  "nil", "false", "true", Numeral, LiteralString, "...", FunctionDef,
  PrefixExp, TableConstructor, span(Exp, BinOp, Exp), span(UnOp, Exp) end)
FunctionCall = factor("FunctionCall", function() return
  span(PrefixExp, Args), span(PrefixExp, ":", Name, Args) end)
Args = factor("Args", function() return
  span("(", opt(ExpList), ")"), TableConstructor, LiteralString end)
FunctionDef = factor("FunctionDef", function() return
  span("function", FuncBody) end)
PrefixExp = factor("PrefixExp", function() return
  Var, FunctionCall, span("(", Exp, ")") end)
FuncBody = factor("FuncBody", function() return
  span("(", opt(ParList), ")", Block, "end") end)
ParList = factor("ParList", function() return
  span(NameList, opt(span(",", "..."))), "..." end)
TableConstructor = factor("TableConstructor", function() return
  span("{", FieldList, "}") end)
FieldList = factor("FieldList", function() return
  span(Field, rep(span(FieldSep, Field)), opt(FieldSep)) end)
FieldSep = factor("FieldSep", function() return
  ",", ";" end)
Field = factor("Field", function() return
  span("[", Exp, "]", "=", Exp), span(Name, "=", Exp), Exp end)
BinOp = factor("BinOp", function() return 
  "^", "*", "/", "//", "%", "+", "-", "..", "<<", ">>", "&", "~", "|", "<",
  ">", "<=", ">=", "~=", "==", "and", "or" end)
UnOp = factor("UnOp", function() return
  "-", "not", "#", "~" end)
LiteralString = factor("LiteralString", function() return
  span("\"", opt(dquoted), "\""),
  span("\'", opt(squoted), "\'") end)

-- Functions
local function stringcontent(quotechar)
  return function(invariant, position, limit)
    local src = invariant.src
    limit = math.min(#src, limit or #src)
    if position > limit then
      return position
    end
    local escaped = false
    local value = {}
    local byte
    for i=position, limit do
      if not escaped and byte == "\\" then
        escaped = true
      else
        if escaped and byte == "n" then
          byte = "\n"
        end
        escaped = false
      end
      if not escaped then
        table.insert(value, byte)
      end
      byte = string.char(invariant.src:byte(i))
      if byte == quotechar and not escaped then
        return i, table.concat(value)
      end
    end
    raise(UnmatchedQuoteException(src, limit))
  end
end

dquoted = stringcontent("\"")
squoted = stringcontent("\'")

Numeral = function(invariant, position, limit, peek)
  local sign, numbers = position
  local src = invariant.src
  limit = limit or #src
  local byte = src:byte(position)
  local dot, zero, nine, minus = 46, 48, 57, 45
  if byte == minus then
    sign = position + 1
  end
  local decimal = false
  local rest
  for i=sign, limit do
    local byte = src:byte(i)
    if i ~= sign and byte == dot and decimal == false then
      decimal = true
    elseif not (byte >= zero and byte <= nine) then
      rest = i
      break
    elseif i == limit then
      rest = limit + 1
    end
  end
  if rest == position or rest == sign then
    -- Not a number
    return nil
  end
  if peek then
    return rest
  end
  return rest, tonumber(src:sub(position, rest-1))
end

Name = function(invariant, position, limit, peek)
  local underscore, alpha, zeta, ALPHA, ZETA = 95, 97, 122, 65, 90
  local zero, nine = 48, 57
  local src = invariant.src
  limit = limit or #src
  local byte = src:byte(position)

  if not (byte == underscore or byte >= alpha and byte <= zeta or byte >= ALPHA
      and byte <= ZETA) then
    return nil
  end

  local rest = position + 1
  for i=position+1, limit do
    byte = src:byte(i)
    if not (byte == underscore or byte >= alpha and byte <= zeta or
        byte >= ALPHA and byte <= ZETA or byte >= zero and byte <= nine) then
      break
    end
    rest = i + 1
  end

  if peek then
    return rest
  end

  return rest, src:sub(position, rest-1)
end

return {
  Chunk=Chunk,
  Block=Block,
  Stat=Stat,
  RetStat=RetStat,
  Label=Label,
  FuncName=FuncName,
  VarList=VarList,
  Var=Var,
  NameList=NameList,
  ExpList=ExpList,
  Exp=Exp,
  PrefixExp=PrefixExp,
  FunctionCall=FunctionCall,
  Args=Args,
  FunctionDef=FunctionDef,
  FuncBody=FuncBody,
  ParList=ParList,
  TableConstructor=TableConstructor,
  FieldList=FieldList,
  Field=Field,
  FieldSep=FieldSep,
  BinOp=BinOp,
  UnOp=UnOp,
  Numeral=Numeral,
  LiteralString=LiteralString,
  Name=Name}
