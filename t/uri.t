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
                    uris = {"/foo"},
                }
            })

            ngx.say(rx:match("/aa/bb", {uri = "/foo"}))
            ngx.say(rx:match("/aa/bb", {uri = "/foo/bar"}))
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
                    uris = {"/aa*"},
                    metadata = "metadata /aa",
                }
            })

            ngx.say(rx:match("/aa/bb", {uri = "/a"}))
            ngx.say(rx:match("/aa/bb", {uri = "/aa"}))
            ngx.say(rx:match("/aa/bb", {uri = "/aa/b"}))
            ngx.say(rx:match("/aa/bb", {uri = "/aa/c/d"}))
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



=== TEST 3: mutiple uris
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    uris = {"/foo", "/bar"},
                }
            })

            ngx.say(rx:match("/aa/bb", {uri = "/foo"}))
            ngx.say(rx:match("/aa/bb", {uri = "/bar"}))
            ngx.say(rx:match("/aa/bb", {uri = "/ggg"}))
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



=== TEST 4: mutiple uri (include prefix)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata /aa",
                    uris = {"/foo", "/bar/*"}
                }
            })

            ngx.say(rx:match("/aa/bb", {uri = "/foo"}))
            ngx.say(rx:match("/aa/bb", {uri = "/bar"}))
            ngx.say(rx:match("/aa/bb", {uri = "/bar/com"}))
            ngx.say(rx:match("/aa/bb", {uri = "/ggg/glo"}))
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
