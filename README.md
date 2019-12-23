Name
====
This is Lua-Openresty implementation library base on FFI for [rax](https://github.com/antirez/rax).

[![Build Status](https://travis-ci.org/iresty/lua-resty-radixtree.svg?branch=master)](https://travis-ci.org/iresty/lua-resty-radixtree)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/iresty/lua-resty-radixtree/blob/master/LICENSE)

This project depends on [lua-resty-ipmatcher](https://github.com/iresty/lua-resty-ipmatcher).

This project has been working in microservices API gateway [Apache APISIX](https://github.com/apache/incubator-apisix).

The project is open sourced by Shenzhen [ZhiLiu](https://www.iresty.com/) Technology Company. In addition to this open source version, our company also provides a more powerful and performing commercial version, and provides technical support. If you are interested in our commercial version, please contact us. email: [yuansheng@iresty.com](yuansheng@iresty.com) .

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
* [Benchmark](#benchmark)

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
                filter_fun = function(vars, opts)
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
|uris      |option  |A list of client request uris, not only supports static uri, but also supports prefix uri.|{"/foo", "/bar/*"}|
|remote_addrs|option  |A list of client remote address(IPv4 and IPv6), and we can use CIDR format, eg `192.168.1.0/24`.|{"127.0.0.1", "192.0.0.0/8", "::1", "fe80::/32"}|
|methods    |option  |A list of method name. Here is full valid method list: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "CONNECT" and "TRACE".|{"GET", "POST"}|
|vars       |option  |A list of `{var, operator, val}`. For example: {{var, operator, val}, {var, operator, val}, ...}, `{"arg_name", "==", "json"}` means the value of argument `name` expect to `json`. Here is the full [Operator List](#operator-list).|{{"arg_name", "==", "json"}, {"arg_age", ">", 18}}|
|filter_fun |option  |User defined filter function, We can use it to achieve matching logic for special scenes. `radixtree` will pass `vars` and other arguments when matching route.|function(vars) return vars["arg_name"] == "json" end|
|priority      |option  |Routing priority, default is 0.|priority = 100|
|metadata   |option  |Will return this field if using `rx:match` to match route.||
|handler    |option  |Will call this function using `rx:dispatch` to match route.||

#### Operator List

|operator|description|example|
|--------|-----------|-------|
|==      |equal      |{"arg_name", "==", "json"}|
|~=      |not equal  |{"arg_name", "~=", "json"}|
|>       |greater than|{"arg_age", ">", 24}|
|<       |less than  |{"arg_age", "<", 24}|
|~~      |Regular match|{"arg_name", "~~", "[a-z]+"}|

[Back to TOC](#table-of-contents)

match
-----

`syntax: metadata = rx:match(path, opts)`

* `path`: client request path.
* `opts`: a Lua tale (optional).
    * `method`: optional, method name of client request.
    * `host`: optional, client request host.
    * `remote_addr`: optional, client remote address like `192.168.1.100`.
    * `uri`: optional, client request uri.
    * `vars`: optional, a Lua table to fetch variable, default value is `ngx.var` to fetch Ningx builtin variable.

Matchs the route by `method`, `path` and `host` etc, and return `metadata` if successful.

```lua
local metadata = rx:match(ngx.var.uri, {...})
```

[Back to TOC](#table-of-contents)

dispatch
--------

`syntax: ok = rx:dispatch(path, opts, ...)`

* `path`: client request path.
* `opts`: a Lua tale (optional).
    * `method`: optional, method name of client request.
    * `host`: optional, client request host.
    * `remote_addr`: optional, client remote address like `192.168.1.100`.
    * `uri`: optional, client request uri.
    * `vars`: optional, a Lua table to fetch variable, default value is `ngx.var` to fetch Ningx builtin variable.

Matchs the route by `method`, `path` and `host` etc, and call `handler` function if successful.

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

We wrote some simple benchmark scripts.
Machine environment: Macbook pro 2015 15-inch i7 2.8G CPU.

```shell
$ make
cc -O2 -g -Wall -fpic -std=c99 -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast -DBUILDING_SO -c src/rax.c -o src/rax.o
cc -O2 -g -Wall -fpic -std=c99 -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast -DBUILDING_SO -c src/easy_rax.c -o src/easy_rax.o
cc -shared -fvisibility=hidden src/rax.o src/easy_rax.o -o librestyradixtree.so

$ resty -I./lib benchmark/match-static.lua
matched res: 500
route count: 100000
match times: 1000000
time used  : 0.089999914169312 sec
QPS        : 11111121

$ resty -I./lib benchmark/match-static.lua
matched res: 500
route count: 100000
match times: 1000000
time used  : 0.094000101089478 sec
QPS        : 10638286

$ resty -I./lib benchmark/match-prefix.lua
matched res: 500
route count: 100000
match times: 1000000
time used  : 0.85500001907349 sec
QPS        : 1169590

$ resty -I./lib benchmark/match-prefix.lua
matched res: 500
route count: 100000
match times: 1000000
time used  : 0.83500003814697 sec
QPS        : 1197604
```

[Back to TOC](#table-of-contents)
