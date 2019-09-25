# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: paths
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/", "/*", "/aa"},
                    metadata = "metadata multipe",
                    path = "/aa*",
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
metadata multipe
metadata multipe
metadata multipe
metadata multipe



=== TEST 2: hosts
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    hosts = {"foo.com", "*.bar.com"}
                }
            })

            ngx.say(rx:match("/aa/bb", {host = "foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = "bar.com"}))
            ngx.say(rx:match("/aa/bb", {host = "www.bar.com"}))
            ngx.say(rx:match("/aa/bb", {host = "ggg.com"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
metadata /aa
nil



=== TEST 3: remote_addrs
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    metadata = "metadata /aa",
                    remote_addrs = {"127.0.0.1", "127.0.0.3", "::1", "::2",
                                    "192.168.0.0/16", "fe80::/16"},
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.2"}))
            ngx.say(rx:match("/aa", {remote_addr = "::2"}))
            ngx.say(rx:match("/aa", {remote_addr = "::3"}))
            ngx.say(rx:match("/aa", {remote_addr = "192.168.1.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "192.138.1.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "fe80::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "fe81::1"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
metadata /aa
nil
metadata /aa
nil
metadata /aa
nil
