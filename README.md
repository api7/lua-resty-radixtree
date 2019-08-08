Name
====
This is Lua-Openresty implementation library base on FFI for [rax](https://github.com/antirez/rax).

[![Build Status](https://travis-ci.org/iresty/lua-resty-radixtree.svg?branch=master)](https://travis-ci.org/iresty/lua-resty-radixtree)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/iresty/lua-resty-radixtree/blob/master/LICENSE)

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsys](#synopsys)
* [Methods](#methods)
    * [new](#new)
    * [match](#match)
* [Install](#install)

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
                path = "/bb",
                metadata = "metadata /bb",
                host = "*.bar.com",
                method = {"GET", "POST", "PUT"},
                remote_addr = "fe80:fe80::/64",
            }
        })

        ngx.say(rx:match("/aa", {host = ngx.var.host,
                                 method = ngx.req_method(),
                                 remote_addr = ngx.var.remote_addr}))
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
* `path`: client request uri.
* `metadata`: Will return this field if matched this route.
* `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
* `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.
* `methods`: optional, It's an array table, we can put one or more method names together. Here is the valid method name: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS".

[Back to TOC](#table-of-contents)


match
-----

`syntax: ok = rx:dispatch(path, opts)`

* `path`: client request uri.
* `opts`: a Lua tale
    * `method`: optional, method name of client request.
    * `host`: optional, client request host, not only supports normal domain name, but also supports wildcard name, both `foo.com` and `*.foo.com` are valid.
    * `remote_addr`: optional, client remote address like `192.168.1.100`, and we can use CIDR format, eg `192.168.1.0/24`.

Dispatchs the path to the controller by `method`, `path` and `host`.

```lua
local metadata = rx:match(ngx.var.uri, {...})
```

[Back to TOC](#table-of-contents)

Install
=======

### Compile and install

```
make install
```
