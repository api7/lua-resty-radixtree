# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: uri args
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 2: uri args(not hit)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=not_hit
--- no_error_log
[error]
--- response_body
nil



=== TEST 3: http header
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"http_test", "v"},
                    }
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- more_headers
test: v
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 4: http header(not hit)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"http_test", "v"},
                    }
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- more_headers
test: not-hit
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil



=== TEST 5: uri args + header + server_port
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                        {"host", "localhost"},
                        {"server_port", "1984"},
                    }
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 6: uri args + header + server_port (not hit)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                        {"host", "localhost"},
                        {"server_port", "1984-not"},
                    }
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
nil



=== TEST 7: uri args + header + server_port (default to use ngx.var)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                        {"host", "localhost"},
                        {"server_port", "1984"},
                    }
                }
            })

            ngx.say(rx:match("/aa", {}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 8: ~=: not hit
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "~=", "v"},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
nil



=== TEST 9: ~=: hit
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "~=", "************"},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 10: argument `a` > 10
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", ">", 10},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=11
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 11: argument `a` > 10
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", ">", 10},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=9
--- no_error_log
[error]
--- response_body
nil



=== TEST 12: invalid operator
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "invalid", 10},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=9
--- no_error_log
[error]
--- response_body
nil



=== TEST 13: uri args
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                    },
                },
                {
                    paths = "/aa",
                    metadata = "metadata /aa2",
                    vars = {
                        {"arg_k", "~=", "not hit"},
                    },
                },
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- response_body
metadata /aa



=== TEST 14: uri args
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "v"},
                    },
                },
                {
                    paths = "/aa",
                    metadata = "metadata /aa2",
                    vars = {
                        {"arg_k", "~=", "not hit"},
                    },
                },
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
        }
    }
--- request
GET /t?k=xxxx
--- no_error_log
[error]
--- response_body
metadata /aa2
