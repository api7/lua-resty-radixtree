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
                    host = "foo.com"
                }
            })

            ngx.say(rx:match("/aa/bb", {host = "foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = "www.foo.com"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil



=== TEST 2: wildcard
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa",
                    host = "*.foo.com"
                }
            })

            ngx.say(rx:match("/aa/bb", {host = "foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = ".foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = "www.foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = "www.bar.foo.com"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
nil
metadata /aa
metadata /aa
