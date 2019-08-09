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
                    path = "/",
                    metadata = "metadata /",
                },
                {
                    prefix_path = "/",
                    metadata = "metadata /*",
                },
                {
                    path = "/aa",
                    metadata = "metadata /aa",
                },
                {
                    prefix_path = "/aa",
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
                    prefix_path = "/aa",
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
                    prefix_path = "/aa",
                    metadata = "metadata /aa",
                },
                {
                    prefix_path = "/bb",
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
                    path = "/aa",
                    metadata = "metadata /aa",
                },
                {
                    path = "/aa/bb",
                    metadata = "metadata /aa/bb",
                },
                {
                    path = "/aa/bb/cc",
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
                    prefix_path = "/aa",
                    metadata = "metadata /aa",
                },
                {
                    prefix_path = "/aa/bb",
                    metadata = "metadata /aa/bb",
                },
                {
                    prefix_path = "/aa/bb/cc",
                    metadata = "metadata /aa/bb/cc",
                    method = {"POST", "PUT"}
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
                    path = "/aa",
                    metadata = "metadata /aa",
                },
                {
                    path = "/aa/bb",
                    metadata = "metadata /aa/bb",
                },
                {
                    path = "/aa/bb/cc",
                    metadata = "metadata /aa/bb/cc",
                    method = {"POST", "PUT"}
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
