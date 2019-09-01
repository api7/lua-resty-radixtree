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
                    uri_args = {"k", "v"},
                }
            })

            ngx.say(rx:match("/aa", {uri_args = {k="v"}}))
            ngx.say(rx:match("/aa", {uri_args = {}}))
            ngx.say(rx:match("/aa", {}))
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



=== TEST 2: invalid uri_args
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa",
                    uri_args = "xxx",
                }
            })
        }
    }
--- request
GET /t
--- error_code: 500
--- error_log
invalid argument uri_args



=== TEST 3: invalid uri_args
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa",
                    uri_args = {"xxx"},
                }
            })
        }
    }
--- request
GET /t
--- error_code: 500
--- error_log
invalid argument uri_args
