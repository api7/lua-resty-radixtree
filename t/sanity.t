# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/"},
                    metadata = "metadata /",
                },
                {
                    paths = {"/*"},
                    metadata = "metadata /*",
                },
                {
                    paths = {"/aa"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa*",
                }
            })

            ngx.say(rx:match("/aa/bb"))
            ngx.say(rx:match("/aa"))
            ngx.say(rx:match("/xx"))
            ngx.say(rx:match("/"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa*
metadata /aa
metadata /*
metadata /



=== TEST 2: prefix
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                }
            })

            ngx.say(rx:match("/aa/bb"))
            ngx.say(rx:match("/aa"))
            ngx.say(rx:match("/"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
metadata /aa
nil



=== TEST 3: multiple route
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                },
                {
                    paths = "/bb*",
                    metadata = "metadata /bb",
                }
            })

            ngx.say(rx:match("/"))
            ngx.say(rx:match("/aa"))
            ngx.say(rx:match("/aa/"))
            ngx.say(rx:match("/aa/bb"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
metadata /aa
metadata /aa
metadata /aa



=== TEST 4: multiple route
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                },
                {
                    paths = "/aa/bb",
                    metadata = "metadata /aa/bb",
                },
                {
                    paths = "/aa/bb/cc",
                    metadata = "metadata /aa/bb/cc",
                }
            })

            ngx.say(rx:match("/aa/bb/cc"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa/bb/cc



=== TEST 5: use `method` to filter route(prefix path)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/aa/bb*"},
                    metadata = "metadata /aa/bb",
                },
                {
                    paths = {"/aa/bb/cc*"},
                    methods = {"POST", "PUT"},
                    metadata = "metadata /aa/bb/cc",
                }
            })

            ngx.say(rx:match("/aa/bb/cc", {method = "GET"}))
            ngx.say(rx:match("/aa/bb/cc", {method = "OPTIONS"}))
            ngx.say(rx:match("/aa/bb/cc", {method = "POST"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa/bb
metadata /aa/bb
metadata /aa/bb/cc



=== TEST 6: use `method` to filter route(path)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/aa/bb"},
                    metadata = "metadata /aa/bb",
                },
                {
                    paths = {"/aa/bb/cc"},
                    methods = {"POST", "PUT"},
                    metadata = "metadata /aa/bb/cc",
                }
            })

            ngx.say(rx:match("/aa/bb/cc", {method = "GET"}))
            ngx.say(rx:match("/aa/bb/cc", {method = "OPTIONS"}))
            ngx.say(rx:match("/aa/bb/cc", {method = "POST"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
nil
metadata /aa/bb/cc



=== TEST 7: missing options when matching
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    hosts = {"foo.com"},
                    methods = {"GET", "POST"},
                    remote_addrs = {"127.0.0.1"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/bb*"},
                    metadata = {"metadata /bb"},
                    hosts = {"*.bar.com", "gloo.com"},
                    methods = {"GET", "POST", "PUT"},
                    remote_addrs = "fe80:fe80::/64",
                }
            })

            -- should hit
            ngx.say(rx:match("/aa", {host = "foo.com",
                                     method = "GET",
                                     remote_addr = "127.0.0.1"}))

            -- missing method
            ngx.say(rx:match("/aa", {host = "foo.com",
                                     remote_addr = "127.0.0.1"}))

            -- missing host
            ngx.say(rx:match("/aa", {method = "GET",
                                     remote_addr = "127.0.0.1"}))

            -- missing remote_addr
            ngx.say(rx:match("/aa", {host = "foo.com",
                                     method = "GET"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
nil
nil



=== TEST 8: method: CONNECT
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    methods = {"CONNECT"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/aa*"},
                    methods = {"PUT"},
                    metadata = "metadata /aa*",
                }
            })

            ngx.say(rx:match("/aa", {method = "CONNECT"}))
            ngx.say(rx:match("/aa/bb", {method = "CONNECT"}))


            ngx.say(rx:match("/aa", {method = "GET"}))
            ngx.say(rx:match("/aa/bb", {method = "GET"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
nil
nil



=== TEST 9: method: TRACE
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    methods = {"TRACE"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/aa*"},
                    methods = {"PUT"},
                    metadata = "metadata /aa*",
                }
            })

            ngx.say(rx:match("/aa", {method = "TRACE"}))
            ngx.say(rx:match("/aa/bb", {method = "TRACE"}))


            ngx.say(rx:match("/aa", {method = "GET"}))
            ngx.say(rx:match("/aa/bb", {method = "GET"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
nil
nil


=== TEST 10: method: PURGE
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    methods = {"PURGE"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/aa*"},
                    methods = {"PUT"},
                    metadata = "metadata /aa*",
                }
            })

            ngx.say(rx:match("/aa", {method = "PURGE"}))
            ngx.say(rx:match("/aa/bb", {method = "PURGE"}))


            ngx.say(rx:match("/aa", {method = "GET"}))
            ngx.say(rx:match("/aa/bb", {method = "GET"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
nil
nil



=== TEST 11: Iterator
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/*"},
                    metadata = "metadata /*",
                },
                {
                    paths = {"/aa/*"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/bb/*"},
                    methods = {"PUT"},
                    metadata = "metadata /bb/*",
                },
                {
                    paths = {"/bb/aa/*"},
                    methods = {"PUT"},
                    metadata = "metadata /bb/aa/*",
                },
            })

            ngx.say(rx:match("/bb/aa/bb"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /*
