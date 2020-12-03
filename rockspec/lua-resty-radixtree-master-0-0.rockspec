package = "lua-resty-radixtree-master"
version = "0-0"
source = {
    url = "git://github.com/iresty/lua-resty-radixtree",
    branch = "master",
}

description = {
    summary = "This is a radixtree implementation base on FFI for Lua-Openresty",
    homepage = "https://github.com/iresty/lua-resty-radixtree",
    license = "Apache License 2.0",
    maintainer = "Yuansheng Wang <membphis@gmail.com>"
}

dependencies = {
    "lua-resty-ipmatcher",
    "lua-resty-expr = 1.0.0",
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
