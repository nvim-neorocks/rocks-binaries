-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/home/runner/work/rocks-binaries/rocks-binaries/.luarocks" };
}
lua_interpreter = "lua";
variables = {
   LUA_DIR = "/home/runner/work/rocks-binaries/rocks-binaries/.lua";
   LUA_BINDIR = "/home/runner/work/rocks-binaries/rocks-binaries/.lua/bin";
}
