package = "lua-resty-radixtree"
version = "1.6-0"
source = {
    url = "git://github.com/iresty/lua-resty-radixtree",
    tag = "v1.6",
}

description = {
    summary = "This is a radixtree implementation base on FFI for Lua-Openresty",
    homepage = "https://github.com/iresty/lua-resty-radixtree",
    license = "Apache License 2.0",
    maintainer = "Yuansheng Wang <membphis@gmail.com>"
}

dependencies = {
    "lua-resty-ipmatcher = 0.2",
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
