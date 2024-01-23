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
--- log_level: debug
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
--- log_level: debug
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



=== TEST 9: disable param match
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
            }, {
                no_param_match = true,
            })

            local opts = {matched = {}}
            local meta = rx:match("/name/json/id/1", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))
            local meta = rx:match("/name/:name/id/:id", opts)
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
match meta: metadata /name
matched: {"_path":"/name/:name/id/:id"}



=== TEST 10: /file/:filename (parameter with special symbol)
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/file/:filename"},
                    metadata = "metadata /file/:filename",
                },
            })

            local opts = {matched = {}}
            -- test [";" | ":" | "@" | "&" | "="]
            local meta = rx:match("/file/123&45@dd:d=test;", opts)
            ngx.say("matched: ", json.encode(opts.matched))
            ngx.say("match meta: ", meta)

            -- test uchar.unreserved.safe ["$" | "-" | "_" | "." | "+"]
            local meta = rx:match("/file/test_a-b+c.lua$", opts)
            ngx.say("matched: ", json.encode(opts.matched))
            ngx.say("match meta: ", meta)

            -- test uchar.unreserved.extra ["!" | "*" | "'" | "(" | ")" | ","]
            local meta = rx:match("/file/t!e*s't,(file)", opts)
            ngx.say("matched: ", json.encode(opts.matched))
            ngx.say("match meta: ", meta)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
matched: {"_path":"/file/:filename","filename":"123&45@dd:d=test;"}
match meta: metadata /file/:filename
matched: {"_path":"/file/:filename","filename":"test_a-b+c.lua$"}
match meta: metadata /file/:filename
matched: {"_path":"/file/:filename","filename":"t!e*s't,(file)"}
match meta: metadata /file/:filename



=== TEST 11: no opts option should work fine
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/user/:user/age/:age"},
                    metadata = "/user/:user/age/:age",
                },
                {
                    paths = {"/user/:user"},
                    metadata = "/user/:user",
                }
            })

            local meta_a = rx:match("/user/foo")
            ngx.say("match meta: ", meta_a)

            local meta_b = rx:match("/user/foo/age/26")
            ngx.say("match meta: ", meta_b)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: /user/:user
match meta: /user/:user/age/:age



=== TEST 12: /name/:name/ (respect trailing slash)
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/name/:name/"},
                    metadata = "metadata /name",
                },
            })

            local opts = {matched = {}}
            local meta = rx:match("/name/json/", opts)
            ngx.say("match meta: ", meta)
            ngx.say("matched: ", json.encode(opts.matched))

            opts.matched = {}
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
matched: {"_path":"/name/:name/","name":"json"}
match meta: nil
matched: []



=== TEST 13: route matching for routes with params and common prefix should not be dependent on registration order
--- config
    location /t {
        content_by_lua_block {
            local json = require("toolkit.json")
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/api/:version/test/api/projects/:project_id/clusters/:cluster_id/nodes/?"},
                    metadata = "long",
                },
                {
                    paths = {"/api/:version/test/api/projects/:project_id"},
                    metadata = "medium",
                },
                {
                    paths = {"/api/:version/test/*subpath"},
                    metadata = "short",
                },
            })

            -- should match long
            local meta = rx:match("/api/v4/test/api/projects/saas/clusters/123/nodes/")
            ngx.say("match meta: ", meta)

            -- should match short
            local meta = rx:match("/api/v4/test/api")
            ngx.say("match meta: ", meta)

            -- should match medium
            local meta = rx:match("/api/v4/test/api/projects/saas")
            ngx.say("match meta: ", meta)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
match meta: long
match meta: short
match meta: medium
