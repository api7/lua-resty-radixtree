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
            local meta = rx:match("/name/json", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))

            meta = rx:match("/name/", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: metadata /name
matched: {"_path":"\/name\/*name","name":"json"}
match meta: metadata /name
matched: {"_path":"\/name\/*name","name":""}



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
            local meta = rx:match("/name/json/foo/bar", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))

            meta = rx:match("/name/", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: metadata /name
matched: {"_path":"\/name\/*",":ext":"json\/foo\/bar"}
match meta: metadata /name
matched: {"_path":"\/name\/*",":ext":""}



=== TEST 3: /name/:name/id/:id
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
            local meta = rx:match("/name/json/id/1", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))

            opts.matched = {}
            meta = rx:match("/name/json/id/", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: metadata /name
matched: {"name":"json","_path":"\/name\/:name\/id\/:id","id":"1"}
match meta: nil
matched: {}



=== TEST 4: /name/:name/id/:id/*other
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
            local meta = rx:match("/name/json/id/1/foo/bar/gloo", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: metadata /name
matched: {"other":"foo\/bar\/gloo","name":"json","_path":"\/name\/:name\/id\/:id\/*other","id":"1"}



=== TEST 5: /name/:name/id/:id (not match)
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
            local meta = rx:match("/name/json", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: nil
matched: {}



=== TEST 6: /name/:name/id/:id
--- config
    location /t {
        content_by_lua_block {
            local json = require("cjson.safe")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa/*", "/bb/cc/*", "/dd/ee/index.html"},
                    methods = {"GET", "POST", "PUT"},
                    hosts = {"foo.com", "*.bar.com"},
                    metadata = "metadata /asf",
                },
            })

            local opts = {matched = {}, method = "GET", uri = "/bb/cc/xx", host = "foo.com"}
            local meta = rx:match("/bb/cc/xx", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))            

        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: metadata /asf
matched: {"_path":"\/bb\/cc\/*",":ext":"xx","_method":"GET","_host":"foo.com"}
