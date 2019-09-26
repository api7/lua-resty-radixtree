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
                    paths = {"/aa"},
                    remote_addrs = {"127.0.0.1"},
                    metadata = "metadata /aa -> 127.0.0.1",
                },
                {
                    paths = {"/bb"},
                    remote_addrs = {"127.0.0.2"},
                    metadata = "metadata /bb -> 127.0.0.2",
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
metadata /bb -> 127.0.0.2



=== TEST 2: 127.0.0.0/24
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    remote_addrs = {"127.0.0.0/24"},
                    metadata = "metadata /aa -> 127.0.0.1",
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
                    paths = {"/aa"},
                    remote_addrs = {"::1"},
                    metadata = "metadata /aa -> ::1",
                },
                {
                    paths = {"/bb"},
                    remote_addrs = {"::2"},
                    metadata = "metadata /aa -> ::2",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "::2"}))
            ngx.say(rx:match("/bb", {remote_addr = "::1"}))
            ngx.say(rx:match("/bb", {remote_addr = "::2"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.1"}))
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
nil



=== TEST 4: ipv6 with mask
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    remote_addrs = {"fe80::1/64"},
                    metadata = "metadata /aa -> fe80::1/64",
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



=== TEST 5: multiple ipv4 address
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    remote_addrs = {"127.0.0.1", "127.0.0.3"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/bb"},
                    remote_addrs = {"127.0.0.2", "127.0.0.3"},
                    metadata = "metadata /bb",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.1"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.2"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.3"}))
            ngx.say(rx:match("/bb", {remote_addr = "127.0.0.1"}))
            ngx.say(rx:match("/bb", {remote_addr = "127.0.0.2"}))
            ngx.say(rx:match("/bb", {remote_addr = "127.0.0.3"}))
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
metadata /bb
metadata /bb



=== TEST 6: multiple ipv6 address
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    remote_addrs = {"::1", "::3"},
                    metadata = "metadata /aa",
                },
                {
                    paths = {"/bb"},
                    remote_addrs = {"::2", "::3"},
                    metadata = "metadata /bb",
                }
            })

            ngx.say(rx:match("/aa", {remote_addr = "::1"}))
            ngx.say(rx:match("/aa", {remote_addr = "::2"}))
            ngx.say(rx:match("/aa", {remote_addr = "::3"}))
            ngx.say(rx:match("/bb", {remote_addr = "::1"}))
            ngx.say(rx:match("/bb", {remote_addr = "::2"}))
            ngx.say(rx:match("/bb", {remote_addr = "::3"}))
            ngx.say(rx:match("/aa", {remote_addr = "127.0.0.1"}))
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
metadata /bb
metadata /bb
nil



=== TEST 7: multiple ip address: v4 + v6
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    remote_addrs = {"127.0.0.1", "127.0.0.3", "::1", "::2",
                                   "192.168.0.0/16", "fe80::/16"},
                    metadata = "metadata /aa",
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
