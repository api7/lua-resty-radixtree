# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: /name/*name
--- config
    location /t {
        content_by_lua_block {
            local json = require("cjson.safe")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/*name"},
                    metadata = "metadata /name",
                },
            })

            local opts = {matched = {}}
            local meta, ext = rx:match("/name/json", opts)
            ngx.say("match: ", meta)
            ngx.say("ext: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match: metadata /name
ext: {"name":"json"}



=== TEST 2: /name/* in path
--- config
    location /t {
        content_by_lua_block {
            local json = require("cjson.safe")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/*"},
                    metadata = "metadata /name",
                },
            })

            local opts = {matched = {}}
            local meta, ext = rx:match("/name/json", opts)
            ngx.say("match: ", meta)
            ngx.say("ext: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match: metadata /name
ext: {":ext":"json"}



=== TEST 3: /name/:name in vars
--- config
    location /name {
        content_by_lua_block {
            local json = require("cjson.safe")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/*"},
                    metadata = "metadata /name",
                    vars = {
                        {"request_uri", "~~~", "/name/:name"},
                    }
                }
            })

            local opts = {matched = {}}
            local meta, ext = rx:match("/name/json", opts)
            ngx.say("match: ", meta)
            ngx.say("ext: ", json.encode(opts.matched))
        }
    }
--- request
GET /name/json
--- no_error_log
[error]
--- response_body
match: metadata /name
ext: {":ext":"json","name":"json"}



=== TEST 4: /name/:name/id/:id
--- config
    location /t {
        content_by_lua_block {
            local json = require("cjson.safe")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/:name/id/:id"},
                    metadata = "metadata /name",
                },
            })

            local opts = {matched = {}}
            local meta, ext = rx:match("/name/json/id/1", opts)
            ngx.say("match: ", meta)
            ngx.say("ext: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match: metadata /name
ext: {"id":"1","name":"json"}



=== TEST 5: /name/:name/id/:id/*other
--- config
    location /t {
        content_by_lua_block {
            local json = require("cjson.safe")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/:name/id/:id/*other"},
                    metadata = "metadata /name",
                },
            })

            local opts = {matched = {}}
            local meta, ext = rx:match("/name/json/id/1/foo/bar/gloo", opts)
            ngx.say("match: ", meta)
            ngx.say("ext: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match: metadata /name
ext: {"other":"foo\/bar\/gloo","name":"json","id":"1"}
