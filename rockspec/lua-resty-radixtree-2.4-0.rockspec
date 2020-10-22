package = "lua-resty-radixtree"
version = "2.4-0"
source = {
    url = "git://github.com/api7/lua-resty-radixtree",
    tag = "v2.4",
}

description = {
    summary = "Adaptive Radix Trees implemented in Lua for Nginx + Lua",
    homepage = "https://github.com/api7/lua-resty-radixtree",
    license = "Apache License 2.0",
    maintainer = "Yuansheng Wang <membphis@gmail.com>"
}

dependencies = {
    "lua-resty-ipmatcher",
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
