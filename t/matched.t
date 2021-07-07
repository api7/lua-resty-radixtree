# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: prefix matching with method, and matched is not nil.
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/hello*",
                    methods = {"GET"},
                    metadata = "metadata prefix matching with GET, matched = {}",
                },
            })
            local opts = {method = "GET", matched = {}}
            ngx.say(rx:match("/hello1", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata prefix matching with GET, matched = {}



=== TEST 2: prefix matching with host, and matched is not nil.
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/hello*",
                    hosts = {"foo.com"},
                    metadata = "metadata prefix matching with host, matched = {}",
                },
            })
            local opts = {host = "foo.com", matched = {}}
            ngx.say(rx:match("/hello1", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata prefix matching with host, matched = {}



=== TEST 3: prefix matching with vars, and matched is not nil.
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/hello*",
                    vars = {
                        {"arg_k", "==", "v"},
                    },
                    metadata = "metadata prefix matching with host, matched = {}",
                },
            })
            local opts = {vars = ngx.var, matched = {}}
            ngx.say(rx:match("/hello1", opts))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata prefix matching with host, matched = {}



=== TEST 4: prefix matching with method, host, vars and matched is not nil.
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/hello*",
                    hosts = {"foo.com"},
                    methods = {"GET"},
                    vars = {
                        {"arg_k", "==", "v"},
                    },
                    metadata = "metadata prefix matching with method, host, vars, matched = {}",
                },
            })
            local opts = {
                    method = "GET",
                    host = "foo.com",
                    vars = ngx.var,
                    matched = {}
            }
            ngx.say(rx:match("/hello1", opts))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata prefix matching with method, host, vars, matched = {}



=== TEST 5: get matched when callback route.handler after dispatch success
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/hello*",
                    hosts = {"foo.com"},
                    methods = {"GET"},
                    vars = {
                        {"arg_k", "==", "v"},
                    },
                    handler = function (opts)
                        ngx.say("after dispatch success get matched: ", json.encode(opts.matched))
                    end,
                },
            })
            local opts = {
                    method = "GET",
                    host = "foo.com",
                    vars = ngx.var,
                    matched = {}
            }
            rx:dispatch("/hello1", opts, opts)
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
after dispatch success get matched: {"_host":"foo.com","_method":"GET","_path":"/hello*"}



=== TEST 6: match uri with '\n'
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "*",
                    metadata = "OK",
                },
            })
            local opts = {method = "GET", matched = {}}
            ngx.say(rx:match("/ip\nA", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK



=== TEST 7: match uri with multiple '\n'
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "*",
                    metadata = "OK",
                },
            })
            local opts = {method = "GET", matched = {}}
            ngx.say(rx:match("/ip\ni\ni", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK
