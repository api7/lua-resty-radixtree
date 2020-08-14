# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: single path
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/",
                    metadata = "metadata /",
                },
            })
            ngx.say(rx:match("/xx"))
            ngx.say(rx:match("/"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
metadata /



=== TEST 2: multiple path
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/", "/aa", "/bb"},
                    metadata = "metadata multipe path 1",
                },
                {
                    paths = {"/cc"},
                    metadata = "metadata multipe path 2",
                },
            })

            ngx.say(rx:match("/"))
            ngx.say(rx:match("/aa"))
            ngx.say(rx:match("/bb"))
            ngx.say(rx:match("/cc"))
            ngx.say(rx:match("/dd"))
            ngx.say(rx:match("/ee"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata multipe path 1
metadata multipe path 1
metadata multipe path 1
metadata multipe path 2
nil
nil



=== TEST 3: multiple path with overlap
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/equal*"},
                    metadata = "metadata multipe path 1",
                },
                {
                    paths = {"/equal123*"},
                    metadata = "metadata multipe path 2",
                },
            })

            ngx.say(rx:match("/equal1"))
            ngx.say(rx:match("/equal12"))
            ngx.say(rx:match("/equal123"))
            ngx.say(rx:match("/equal1234"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
pcre pat:
--- response_body
metadata multipe path 1
metadata multipe path 1
metadata multipe path 2
metadata multipe path 2
