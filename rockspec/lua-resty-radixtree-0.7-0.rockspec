package = "lua-resty-radixtree"
version = "0.7-0"
source = {
    url = "git://github.com/iresty/lua-resty-radixtree",
    branch = "v0.7",
}

description = {
    summary = "This is a radixtree implementation base on FFI for Lua-Openresty",
    homepage = "https://github.com/iresty/lua-resty-radixtree",
    license = "Apache License 2.0",
    maintainer = "Yuansheng Wang <membphis@gmail.com>"
}

build = {
    type = "make",
    build_variables = {
            CFLAGS="$(CFLAGS) -std=c99 -g",
            LIBFLAG="$(LIBFLAG)",
            LUA_LIBDIR="$(LUA_LIBDIR)",
            LUA_BINDIR="$(LUA_BINDIR)",
            LUA_INCDIR="$(LUA_INCDIR)",
            LUA="$(LUA)",
        },
        install_variables = {
            INST_PREFIX="$(PREFIX)",
            INST_BINDIR="$(BINDIR)",
            INST_LIBDIR="$(LIBDIR)",
            INST_LUADIR="$(LUADIR)",
            INST_CONFDIR="$(CONFDIR)",
        },
}
