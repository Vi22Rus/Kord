-- Local only: compile a Lua file without executing its addon logic.
local path=arg and arg[1]
assert(type(path)=="string" and path~="", "usage: check_lua_syntax.lua <path>")
local chunk,err=loadfile(path)
assert(chunk,err)
