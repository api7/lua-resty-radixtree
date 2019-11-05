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
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    hosts = {"foo.com"},
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
                    paths = {"/aa*"},
                    hosts = {"*.foo.com"},
                    metadata = "metadata /aa",
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
metadata /aa
metadata /aa
metadata /aa



=== TEST 3: mutiple domain
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    hosts = {"foo.com", "bar.com"},
                }
            })

            ngx.say(rx:match("/aa/bb", {host = "foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = "bar.com"}))
            ngx.say(rx:match("/aa/bb", {host = "ggg.com"}))
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



=== TEST 4: mutiple domain (wildcard domain)
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



=== TEST 5: mutiple domain (wildcard domain)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa/bb*"},
                    metadata = "metadata /aa1",
                    hosts = {"*.bar.com"}
                },
                {
                    paths = {"/aa/bb*"},
                    metadata = "metadata /aa2",
                    hosts = {"*.foo.bar.com"}
                },
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa3",
                },
                {
                    paths = {"/aa/bb*"},
                    metadata = "metadata /aa4",
                    hosts = {"*.bar.com"}
                }
            })
            ngx.say(rx:match("/aa/bb", {host = "qqq.foo.bar.com"}))
            ngx.say(rx:match("/aa/bb/1", {host = "1.bar.com"}))
            ngx.say(rx:match("/aa/bb", {host = "bar.com"}))
            ngx.say(rx:match("/aa/bb/2", {host = "qqq.foo.bar.com"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa2
metadata /aa1
metadata /aa3
metadata /aa2
