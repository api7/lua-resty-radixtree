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
                    path = "/aa",
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



=== TEST 2: multiple route
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
                    path = "/bb",
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



=== TEST 3: multiple route
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
