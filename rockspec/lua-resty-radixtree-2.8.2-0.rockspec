package = "lua-resty-radixtree"
version = "2.8.2-0"
source = {
    url = "git://github.com/api7/lua-resty-radixtree",
    branch = "v2.8.2",
}

description = {
    summary = "Adaptive Radix Trees implemented in Lua for Nginx + Lua",
    homepage = "https://github.com/api7/lua-resty-radixtree",
    license = "Apache License 2.0",
}

dependencies = {
    "lua-resty-ipmatcher",
    "lua-resty-expr = 1.3.0",
}


build = {
    type = "make",
    build_variables = {
            CFLAGS="$(CFLAGS) -std=c99 -g -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast",
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

