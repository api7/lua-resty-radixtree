# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: /name/*name
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
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
matched: {"_path":"/name/*name","name":"json"}
match meta: metadata /name
matched: {"_path":"/name/*name","name":""}



=== TEST 2: /name/* in path
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
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
matched: {":ext":"json/foo/bar","_path":"/name/*"}
match meta: metadata /name
matched: {":ext":"","_path":"/name/*"}



=== TEST 3: /name/:name/id/:id
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
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
matched: {"_path":"/name/:name/id/:id","id":"1","name":"json"}
match meta: nil
matched: []



=== TEST 4: /name/:name/id/:id/*other
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
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
matched: {"_path":"/name/:name/id/:id/*other","id":"1","name":"json","other":"foo/bar/gloo"}



=== TEST 5: /name/:name/id/:id (not match)
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
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
matched: []



=== TEST 6: /name/:name/foo (cached parameter)
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/:name/foo"},
                    metadata = "metadata /name",
                },
            })

            local opts = {matched = {}}
            local meta = rx:match("/name/json/foo", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))

            meta = rx:match("/name/json", opts)
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
matched: {"_path":"/name/:name/foo","name":"json"}
match meta: nil
matched: []



=== TEST 7: /name/:name/foo (no cached parameter)
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/:name/foo"},
                    metadata = "metadata /name",
                },
            })

            local opts = {}
            local meta = rx:match("/name/json/foo", opts)
            ngx.say("match meta: ", meta)
            meta = rx:match("/name/json", opts)
            ngx.say("match meta: ", meta)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: metadata /name
match meta: nil
--- error_log
pcre pat:



=== TEST 8: /:name/foo
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/:name/foo"},
                    metadata = "metadata /:name/foo",
                },
            })

            local opts = {matched = {}}
            local meta = rx:match("/json/", opts)
            ngx.say("match meta: ", meta)

            meta = rx:match("/json/bar", opts)
            ngx.say("match meta: ", meta)

            meta = rx:match("/json/foo", opts)
            ngx.say("match meta: ", meta)

            meta = rx:match("/json/foo/bar", opts)
            ngx.say("match meta: ", meta)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: nil
match meta: nil
match meta: metadata /:name/foo
match meta: nil
--- error_log
pcre pat:
