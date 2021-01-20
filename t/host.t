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

            local opts = {host = "foo.com", matched = {}}
            rx:match("/aa/bb", opts)
            ngx.say("matched: ", opts.matched._host)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
matched: foo.com



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

            local opts = {host = "www.foo.com", matched = {}}
            rx:match("/aa/bb", opts)
            ngx.say("matched: ", opts.matched._host)
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
matched: *.foo.com



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



=== TEST 5: hosts in string type
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    hosts = "foo.com",
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



=== TEST 6: wildcard hosts in string type
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    hosts = "*.foo.com",
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



=== TEST 7: hosts contains uppercase
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    hosts = {"foo.cOm"},
                }
            })

            ngx.say(rx:match("/aa/bb", {host = "foo.com"}))
            ngx.say(rx:match("/aa/bb", {host = "www.foo.com"}))

            local opts = {host = "foo.com", matched = {}}
            rx:match("/aa/bb", opts)
            ngx.say("matched: ", opts.matched._host)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
matched: foo.com



=== TEST 8: opt.host contains uppercase
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

            local opts = {host = "foo.cOm", matched = {}}
            rx:match("/aa/bb", opts)
            ngx.say("matched: ", opts.matched._host)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa
nil
matched: foo.com
