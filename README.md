# Name

Radix tree implementation based on [rax](https://github.com/antirez/rax).

## Status

[![Build Status](https://github.com/api7/lua-resty-radixtree/actions/workflows/test.yml/badge.svg)](https://github.com/api7/lua-resty-radixtree/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/iresty/lua-resty-radixtree/blob/master/LICENSE)

Dependencies:

- [lua-resty-ipmatcher](https://github.com/api7/lua-resty-ipmatcher)
- [lua-resty-expr](https://github.com/api7/lua-resty-expr)

Used by:

- [Apache APISIX](https://github.com/apache/apisix): A high-performance cloud native API gateway.

Developed by [API7.ai](https://api7.ai/).

> **Note**
>
> API7.ai provides technical support for the software it maintains like this library and [Apache APISIX](https://github.com/apache/apisix). Please [contact us](https://api7.ai/contact) to learn more.

# Table of Contents

- [Name](#name)
  - [Status](#status)
- [Table of Contents](#table-of-contents)
- [Synopsis](#synopsis)
- [Methods](#methods)
  - [new](#new)
    - [Usage](#usage)
    - [Attributes](#attributes)
  - [match](#match)
    - [Usage](#usage-1)
    - [Attributes](#attributes-1)
  - [dispatch](#dispatch)
    - [Usage](#usage-2)
    - [Attributes](#attributes-2)
- [Examples](#examples)
  - [Full Path Match](#full-path-match)
  - [Prefix Match](#prefix-match)
  - [Parameters in Path](#parameters-in-path)
- [Installation](#installation)
  - [From LuaRocks](#from-luarocks)
  - [From Source](#from-source)
- [Development](#development)
- [Benchmarks](#benchmarks)

# Synopsis

```lua
location / {
  set $arg_access 'admin';
  content_by_lua_block {
    local radix = require("resty.radixtree")
    local rx = radix.new({
        {
            paths = { "/login/*action" },
            metadata = { "metadata /login/action" },
            methods = { "GET", "POST", "PUT" },
            remote_addrs = { "127.0.0.1", "192.168.0.0/16", "::1", "fe80::/32" }
        },
        {
            paths = { "/user/:name" },
            metadata = { "metadata /user/name" },
            methods = { "GET" },
        },
        {
            paths = { "/admin/:name", "/superuser/:name" },
            metadata = { "metadata /admin/name" },
            methods = { "GET", "POST", "PUT" },
            filter_fun = function(vars, opts)
                return vars["arg_access"] == "admin"
            end
        }
    })

    local opts = {
        method = "POST",
        remote_addr = "127.0.0.1",
        matched = {}
    }

    -- matches the first route
    ngx.say(rx:match("/login/update", opts))   -- metadata /login/action
    ngx.say("action: ", opts.matched.action)   -- action: update

    ngx.say(rx:match("/login/register", opts)) -- metadata /login/action
    ngx.say("action: ", opts.matched.action)   -- action: register

    local opts = {
        method = "GET",
        matched = {}
    }

    -- matches the second route
    ngx.say(rx:match("/user/john", opts)) -- metadata /user/name
    ngx.say("name: ", opts.matched.name)  -- name: john

    local opts = {
        method = "POST",
        vars = ngx.var,
        matched = {}
    }

    -- matches the third route
    ngx.say(rx:match("/admin/jane", opts))     -- metadata /admin/name
    ngx.say("admin name: ", opts.matched.name) -- admin name: jane
    }
}
```

[Back to TOC](#table-of-contents)

# Methods

## new

Creates a new radix tree to store routes.

### Usage

```lua
rx, err = radix.new(routes, opts)
```

### Attributes

`routes` is an array (`{ {...}, {...}, {...} }`) where each element is a route.

Each route can have the following attributes:

| Name         | Required? | Description                                                                                                                                                                                                  | Example                                              |
| ------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| paths        | Required  | List of request paths to match the route. By default does a full match. Adding `*` at the end will result in prefix match. For example, `/foo*` can match requests with paths `/foo/bar` and `/foo/car/far`. | {"/", "/foo", "/bar/\*"}                             |
| hosts        | Optional  | List of host addresses to match the route. Supports wildcards. For example `*.bar.com` can match `foo.bar.com` and `car.bar.com`.                                                                            | {"foo.com", "\*.bar.com"}                            |
| remote_addrs | Optional  | List of remote addresses (IPv4 or IPv6) to match the route. Supports CIDR format.                                                                                                                            | {"127.0.0.1", "192.0.0.0/8", "::1", "fe80::/32"}     |
| methods      | Optional  | List of HTTP methods to match the route. Valid values: "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS", "CONNECT" and "TRACE".                                                                    | {"GET", "POST"}                                      |
| vars         | Optional  | DSL to evaluate with the provided `opts.vars` or `ngx.var`. See: [lua-resty-expr](https://github.com/api7/lua-resty-expr#new).                                                                               | {{"arg_name", "==", "json"}, {"arg_age", ">", 18}}   |
| filter_fun   | Optional  | User defined filter function to match the route. Can be used for custom matching scenarios. `vars` and `opts` will be passed to the function when matching a route.                                          | function(vars) return vars["arg_name"] == "json" end |
| priority     | Optional  | Route priority. Defaults to 0.                                                                                                                                                                               | priority = 100                                       |
| metadata     | Optional  | `metadata` will be returned when a route matches while using `rx:match`.                                                                                                                                     |                                                      |
| handler      | Optional  | `handler` function will be called when a route matches while using `rx:dispatch`.                                                                                                                            |                                                      |

`opts` is an optional configuration that controls the behavior of a match. It can have the following attribute:

| Name           | Description                                         | Default |
| -------------- | --------------------------------------------------- | ------- |
| no_param_match | Disables [Parameters in path](#parameters-in-path). | false   |

[Back to TOC](#table-of-contents)

## match

Matches client request with routes and returns `metadata` if successful.

### Usage

```lua
metadata = rx:match(path, opts)
```

### Attributes

`path` is the client request path. For example, `"/foo/bar"`, `/user/john/send`.

`opts` is an optional attribute and a table. It can have the following attributes:

| Name        | Required? | Description                                                                          |
| ----------- | --------- | ------------------------------------------------------------------------------------ |
| method      | Optional  | HTTP method of the client request.                                                   |
| host        | Optional  | Host address of the client request.                                                  |
| remote_addr | Optional  | Remote address (IPv4 or IPv6) of the client. Supports CIDR format.                   |
| paths       | Optional  | A list of client request paths.                                                      |
| vars        | Optional  | A table to fetch variables. Defaults to `ngx.var` to fetch built-in Nginx variables. |

[Back to TOC](#table-of-contents)

## dispatch

Matches client requests with routes and calls the `handler` function if successful.

### Usage

```lua
ok = rx:dispatch(path, opts, ...)
```

### Attributes

`path` is the client request path. For example, `"/api/metrics"`, `/admin/john/login`.

`opts` is an optional attribute and a table. It can have the following attributes:

| Name        | Required? | Description                                                                          |
| ----------- | --------- | ------------------------------------------------------------------------------------ |
| method      | Optional  | HTTP method of the client request.                                                   |
| host        | Optional  | Host address of the client request.                                                  |
| remote_addr | Optional  | Remote address (IPv4 or IPv6) of the client. Supports CIDR format.                   |
| paths       | Optional  | A list of client request paths.                                                      |
| vars        | Optional  | A table to fetch variables. Defaults to `ngx.var` to fetch built-in Nginx variables. |

[Back to TOC](#table-of-contents)

# Examples

## Full Path Match

Matching full paths with multiple paths specified:

```lua
local rx = radix.new({
    {
        paths = {"/foo", "/bar/car", "/doo/soo/index.html"},
        metadata = "metadata /foo",
    },
    {
        paths = {"/example"},
        metadata = "metadata /example",
    },
    {
        paths = {"/index.html"},
        metadata = "metadata /index.html",
    },
})
```

## Prefix Match

Matching based on prefix with multiple paths specified:

```lua
local rx = radix.new({
    {
        paths = {"/foo/*", "/bar/car/*"}, -- matches with `/foo/boo`, `/bar/car/sar/far`, etc.
        metadata = "metadata /foo",
    },
    {
        paths = {"/example/*"}, -- matches with `/example/boo`, `/example/car/sar/far`, etc.
        metadata = "metadata /example",
    },
})
```

## Parameters in Path

You can specify parameters on a path. These can then be dynamically obtained from `opts.matched.parameter-name`:

```lua
local rx = radix.new({
    {
        -- matches with `/user/john` but not `/user/` or `/user`
        paths = {"/user/:user"}, -- for `/user/john`, `opts.matched.user` will be `john`
        metadata = "metadata /user",
    },
    {
        -- But this will match `/user/john/` and also `/user/john/send`
        paths = {"/user/:user/*action"}, -- for `/user/john/send`, `opts.matched.user` will be `john` and `opts.matched.action` will be `send`
        metadata = "metadata action",
    },
})
```

[Back to TOC](#table-of-contents)

# Installation

## From LuaRocks

```shell
luarocks install lua-resty-radixtree
```

## From Source

```shell
make install
```

[Back to TOC](#table-of-contents)

# Development

To install dependencies, run:

```shell
make deps
```

[Back to TOC](#table-of-contents)

# Benchmarks

These are [simple benchmarks](./benchmark/).

Environment: MacBook Pro (16-inch, 2019), CPU 2.3 GHz Intel Core i9.

To start benchmarking, run:

```shell
make
```

```shell
make bench
```

Results:

```shell
resty -I=./lib -I=./deps/share/lua/5.1 benchmark/match-parameter.lua
matched res: 1
route count: 100000
match times: 10000000
time used  : 3.1400001049042 sec
QPS        : 3184713
each time  : 0.31400001049042 ns

resty -I=./lib -I=./deps/share/lua/5.1 benchmark/match-prefix.lua
matched res: 500
route count: 100000
match times: 1000000
time used  : 0.42700004577637 sec
QPS        : 2341920

resty -I=./lib -I=./deps/share/lua/5.1 benchmark/match-static.lua
matched res: 500
route count: 100000
match times: 10000000
time used  : 0.95000004768372 sec
QPS        : 10526315

resty -I=./lib -I=./deps/share/lua/5.1 benchmark/match-hosts.lua
matched res: 500
route count: 1000
match times: 100000
time used  : 0.60199999809265 sec
QPS        : 166112

resty -I=./lib -I=./deps/share/lua/5.1 benchmark/match-wildcard-hosts.lua
matched res: 500
route count: 1000
match times: 50000
time used  : 0.47900009155273 sec
QPS        : 104384
```

[Back to TOC](#table-of-contents)
