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
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [match](#match)
    * [dispatch](#dispatch)
* [Install](#install)
* [DEV ENV](#dev-env)

Status
======

**This repository is an experimental.**

Synopsis
========

```lua
 location / {
     content_by_lua_block {
        local radix = require("resty.radixtree")
        local rx = radix.new({
            {
                paths = {"/bb*", "/aa"},
                hosts = {"*.bar.com", "foo.com"},
                methods = {"GET", "POST", "PUT"},
                remote_addrs = {"127.0.0.1","192.168.0.0/16",
                                "::1", "fe80::/32"},
                vars = {
                    {"arg_name", "==", "json"},
                    {"arg_weight", ">", 10},
                },
                filter_fun = function(vars)
                    return vars["arg_name"] == "json"
                end,

                metadata = "metadata /bb",
            }
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

`syntax: rx, err = radix.new(routes)`

The routes is a array table, like `{ {...}, {...}, {...} }`, Each element in the array is a route, which is a hash table.

The attributes of each element may contain these:

|name       |option  |description|example|
|:--------  |:--------|:-----------|:-----|
|paths      |required|A list of client request uri. The default is a full match, but if the end of the path is `*`, it means that this is a prefix path. For example `/foo*`, it'll match `/foo/bar` or `/foo/glo/grey` etc.|{"/", "/aa", "/bb"}|
|hosts      |option  |A list of client request host, not only supports normal domain name, but also supports wildcard name.|{"foo.com", "*.bar.com"}|
|remote_addrs|option  |A list of client remote address(IPv4 and IPv6), and we can use CIDR format, eg `192.168.1.0/24`.|{"127.0.0.1", "192.0.0.0/8", "::1", "fe80::/32"}|
|methods    |option  |A list of method name. Here is full valid method list: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "CONNECT" and "TRACE".|{"GET", "POST"}|
|vars       |option  |A list of `{var, operator, val}`. For example: {{var, operator, val}, {var, operator, val}, ...}, `{"arg_name", "==", "json"}` means the value of argument `name` expect to `json`.|{{"arg_name", "==", "json"}, {"arg_age", ">", 18}}|
|filter_fun |option  |User defined filter function, We can use it to achieve matching logic for special scenes. `radixtree` will only pass one parameter which named `vars` when matching route.|function(vars) return vars["arg_name"] == "json" end|
|metadata   |option  |Will return this field if using `rx:match` to match route.||
|handler    |option  |Will call this function using `rx:dispatch` to match route.||
[Back to TOC](#table-of-contents)


match
-----

`syntax: metadata = rx:match(path, opts)`

* `path`: client request uri.
* `opts`: a Lua tale (optional).
    * `method`: optional, method name of client request.
    * `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
    * `remote_addr`: optional, client remote address like `192.168.1.100`.
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
    * `remote_addr`: optional, client remote address like `192.168.1.100`.
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

Benchmark
=========

This is a test example and the result, on my laptop, a single core CPU can match 1 million times in 1.4 seconds (based on 100,000 routes).

```shell
$ cat test.lua
local radix = require("resty.radixtree")

local routes = {}
for i = 1, 1000 * 100 do
    routes[i] = {paths = {"/" .. ngx.md5(i) .. "/*"}, metadata = i}
end

local rx = radix.new(routes)

local res
local uri = "/" .. ngx.md5(300) .. "/a"
for _ = 1, 1000 * 1000 do
    res = rx:match(uri)
end

ngx.say(res)

$ time resty test.lua
800
resty test.lua  1.31s user 0.07s system 100% cpu 1.378 total
```

[Back to TOC](#table-of-contents)
