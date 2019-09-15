Name
====
This is Lua-Openresty implementation library base on FFI for [rax](https://github.com/antirez/rax).

[![Build Status](https://travis-ci.org/iresty/lua-resty-radixtree.svg?branch=master)](https://travis-ci.org/iresty/lua-resty-radixtree)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/iresty/lua-resty-radixtree/blob/master/LICENSE)

This project depends on [lua-resty-ipmatcher](https://github.com/iresty/lua-resty-ipmatcher).

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsys](#synopsys)
* [Methods](#methods)
    * [new](#new)
    * [match](#match)
    * [dispatch](#dispatch)
* [Install](#install)
* [DEV ENV](#dev-env)

Status
======

**This repository is an experimental.**

Synopsys
========

```lua
 location / {
     content_by_lua_block {
        local radix = require("resty.radixtree")
        local rx = radix.new({
            {
                path = "/aa",
                metadata = "metadata /aa",
                host = "foo.com",
                method = {"GET", "POST"},
                remote_addr = "127.0.0.1",
            },
            {
                path = "/bb*",
                metadata = "metadata /bb",
                host = {"*.bar.com", "gloo.com"},
                method = {"GET", "POST", "PUT"},
                remote_addr = "fe80:fe80::/64",
                vars = {
                    {"arg_name", "==", "json"},
                    {"arg_weight", ">", "10"},
                },
                filter_fun = function(vars)
                    return vars["arg_name"] == "json"
                end,
            },
            {
                path = "/cc",
                metadata = "metadata /cc",
                remote_addr = {"127.0.0.1","192.168.0.0/16",
                               "::1", "fe80::/32"}
            },
        })

        -- try to match
        ngx.say(rx:match("/aa", {host = "foo.com",
                                 method = "GET",
                                 remote_addr = "127.0.0.1",
                                 vars = ngx.var}))
     }
 }
```

[Back to TOC](#table-of-contents)

Methods
=======

new
---

`syntax: rx, err = radix:new(routes)`

The routes is a array table, like `{ {...}, {...}, {...} }`, Each element in the array is a route, which is a hash table.

The attributes of each element may contain these:

|name       |option  |description|
|--------   |--------|-----------|
|path       |required|client request uri, the default is a full match. But if the end of the path is `*`, it means that this is a prefix path. For example `/foo*`, it'll match `/foo/bar` or `/foo/glo/grey` etc.|
|metadata   |option  |Will return this field if using `rx:match` to match route.|
|handler    |option  |Will call this function using `rx:dispatch` to match route.|
|host       |option  |Client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.|
|remote_addr|option  |Client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`. BTW, In addition to supporting the IPv6 format, multiple IP addresses are allowed, this field will be an array table at this case, the elements of array shoud be a string IPv4 or IPv6 address.|
|method     |option  |It's an array table, we can put one or more method names together. Here is the valid method list: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "CONNECT" and "TRACE".|
|vars       |option  |It is an array of one or more {var, operator, val} elements. For example: {{var, operator, val}, {var, operator, val}, ...}. `{"arg_key", "==", "val"}` means the value of argument `key` expect to `val`.|
|filter_fun |option  |User defined filter function, We can use it to achieve matching logic for special scenes. `radixtree` will only pass one parameter which named `vars` when matching route.|

[Back to TOC](#table-of-contents)


match
-----

`syntax: metadata = rx:match(path, opts)`

* `path`: client request uri.
* `opts`: a Lua tale (optional).
    * `method`: optional, method name of client request.
    * `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
    * `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.
    * `vars`: optional, a Lua table to fetch variable, default value is `ngx.var` to fetch Ningx builtin variable.

Matchs the route by `method`, `path` and `host`, and return `metadata` if successful.

```lua
local metadata = rx:match(ngx.var.uri, {...})
```

[Back to TOC](#table-of-contents)

dispatch
--------

`syntax: ok = rx:dispatch(path, opts, ...)`

* `path`: client request uri.
* `opts`: a Lua tale (optional).
    * `method`: optional, method name of client request.
    * `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
    * `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.
    * `vars`: optional, a Lua table to fetch variable, default value is `ngx.var` to fetch Ningx builtin variable.

Dispatchs the route by `method`, `path` and `host`, and call `handler` function if successful.

```lua
local ok = rx:dispatch(ngx.var.uri, {...})
```

[Back to TOC](#table-of-contents)

Install
=======

### Compile and install

```
make install
```

[Back to TOC](#table-of-contents)


DEV ENV
=======


### Install Dependencies

```
make dev
```
