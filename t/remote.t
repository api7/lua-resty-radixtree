# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: ipv4
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa -> 127.0.0.1",
                    remote_addr = "127.0.0.1",
                },
                {
                    path = "/bb",
                    metadata = "metadata /aa -> 127.0.0.2",
                    remote_addr = "127.0.0.2",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.2"}))
            ngx.say(rx:match("/bb", {remote_addr = "127.0.0.1"}))
            ngx.say(rx:match("/bb", {remote_addr = "127.0.0.2"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa -> 127.0.0.1
nil
nil
metadata /aa -> 127.0.0.2



=== TEST 2: 127.0.0.0/24
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa -> 127.0.0.1",
                    remote_addr = "127.0.0.0/24",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.2"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.1.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.2.2"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa -> 127.0.0.1
metadata /aa -> 127.0.0.1
nil
nil



=== TEST 3: ipv6
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa -> ::1",
                    remote_addr = "::1",
                },
                {
                    path = "/bb",
                    metadata = "metadata /aa -> ::2",
                    remote_addr = "::2",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "::2"}))
            ngx.say(rx:match("/bb", {remote_addr = "::1"}))
            ngx.say(rx:match("/bb", {remote_addr = "::2"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa -> ::1
nil
nil
metadata /aa -> ::2



=== TEST 4: ipv6 with mask
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    path = "/aa",
                    metadata = "metadata /aa -> fe80::1/64",
                    remote_addr = "fe80::1/64",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "fe80::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "fe80:fe::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "80::1"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
metadata /aa -> fe80::1/64
nil
nil
