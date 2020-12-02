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
                        {"arg_k", "==", "v"},
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
                        {"http_test", "==", "v"},
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
                        {"arg_k", "==", "v"},
                        {"host", "==", "localhost"},
                        {"server_port", "==", "1984"},
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
                        {"arg_k", "==", "v"},
                        {"host", "==", "localhost"},
                        {"server_port", "==", "1984"},
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
            local ok, err = pcall(radix.new, {
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "invalid", 10},
                    },
                }
            })

            ngx.say(ok, " ", err)
        }
    }
--- request
GET /t?k=9
--- no_error_log
[error]
--- response_body_like eval
qr/failed to handle expression: invalid operator 'invalid'/



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
                        {"arg_k", "==", "v"},
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



=== TEST 15: uri args
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local routes = {}
            for i, reg in ipairs({"[0-9]+", "^1[0-9]+", "[1-3]+", "^[1-3]+",
                                  "^2[0-9]+", "[1-3]+$", "[a-z]+", "[0"}) do
                routes[i] = {
                    paths = "/" .. i,
                    metadata = "metadata /" .. i,
                    vars = {
                        {"arg_k", "~~", reg},
                    }
                }
            end
            local rx = radix.new(routes)

            for i =1, 8 do
                ngx.say(rx:match("/" .. i, {vars = ngx.var}))
            end
        }
    }
--- request
GET /t?k=1234
--- no_error_log
[error]
--- response_body
metadata /1
metadata /2
metadata /3
metadata /4
nil
nil
nil
nil



=== TEST 16: have no uri args
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

            ngx.say(rx:match("/aa", {vars = {}}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil



=== TEST 17: ~= nil
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "~=", nil},
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



=== TEST 18: IN: hit
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"arg_k", "in", {'1','2'}},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
            ngx.say(rx:match("/aa", {vars = {arg_k='2'}}))
            ngx.say(rx:match("/aa", {vars = {arg_k='4'}}))
            ngx.say(rx:match("/aa", {vars = {}}))
            ngx.say(rx:match("/aa", {vars = {arg_k=nil}}))
        }
    }
--- request
GET /t?k=1
--- no_error_log
[error]
--- response_body
metadata /aa
metadata /aa
nil
nil
nil



=== TEST 19: operator has
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    vars = {
                        {"x", "has", "a"},
                    },
                }
            })

            ngx.say(rx:match("/aa", {vars = {x = {'a', 'b'}}}))
            ngx.say(rx:match("/aa", {vars = {x = {'a'}}}))
            ngx.say(rx:match("/aa", {vars = {x = {'b'}}}))
            ngx.say(rx:match("/aa", {vars = {x = {}}}))
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
nil
