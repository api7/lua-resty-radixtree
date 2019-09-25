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
                    paths ="/",
                    handler = function (ctx)
                        ngx.say("handler /")
                    end,
                },
                {
                    paths ="/*",
                    handler = function (ctx)
                        ngx.say("handler /*")
                    end,
                },
                {
                    paths ="/aa",
                    handler = function (ctx)
                        ngx.say("handler /aa")
                    end,
                },
                {
                    paths ="/aa*",
                    handler = function (ctx)
                        ngx.say("handler /aa*")
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa/bb"))
            ngx.say(rx:dispatch("/aa"))
            ngx.say(rx:dispatch("/xx"))
            ngx.say(rx:dispatch("/"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
handler /aa*
true
handler /aa
true
handler /*
true
handler /
true



=== TEST 2: prefix
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths ="/aa*",
                    handler = function (n)
                        ngx.say("handler /aa*", n)
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa/bb", nil, 1))
            ngx.say(rx:dispatch("/aa", nil, 2))
            ngx.say(rx:dispatch("/", nil, 3))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
handler /aa*1
true
handler /aa*2
true
nil



=== TEST 3: multiple route
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths ="/aa*",
                    handler = function ()
                        ngx.say("handler /aa*")
                    end,
                },
                {
                    paths ="/bb*",
                    handler = function ()
                        ngx.say("handler /bb*")
                    end,
                }
            })

            ngx.say(rx:dispatch("/"))
            ngx.say(rx:dispatch("/aa"))
            ngx.say(rx:dispatch("/aa/"))
            ngx.say(rx:dispatch("/aa/bb"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
handler /aa*
true
handler /aa*
true
handler /aa*
true



=== TEST 4: multiple route
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths ="/aa",
                    handler = function ()
                        ngx.say("handler /aa")
                    end,
                },
                {
                    paths ="/aa/bb",
                    handler = function ()
                        ngx.say("handler /bb")
                    end,
                },
                {
                    paths ="/aa/bb/cc",
                    handler = function ()
                        ngx.say("handler /aa/bb/cc")
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa/bb/cc"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
handler /aa/bb/cc
true



=== TEST 5: use `method` to filter route(prefix path)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths ="/aa*",
                    handler = function ()
                        ngx.say("handler /aa*")
                    end,
                },
                {
                    paths ="/aa/bb*",
                    handler = function ()
                        ngx.say("handler /aa/bb*")
                    end,
                },
                {
                    paths ="/aa/bb/cc*",
                    methods = {"POST", "PUT"},
                    handler = function ()
                        ngx.say("handler /aa/bb/cc*")
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa/bb/cc", {method = "GET"}))
            ngx.say(rx:dispatch("/aa/bb/cc", {method = "OPTIONS"}))
            ngx.say(rx:dispatch("/aa/bb/cc", {method = "POST"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
handler /aa/bb*
true
handler /aa/bb*
true
handler /aa/bb/cc*
true



=== TEST 6: use `method` to filter route(path)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths ="/aa",
                    handler = function ()
                        ngx.say("handler /aa")
                    end,
                },
                {
                    paths ="/aa/bb",
                    handler = function ()
                        ngx.say("handler /aa/bb")
                    end,
                },
                {
                    paths ="/aa/bb/cc",
                    methods = {"POST", "PUT"},
                    handler = function ()
                        ngx.say("handler /aa/bb/cc")
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa/bb/cc", {method = "GET"}))
            ngx.say(rx:dispatch("/aa/bb/cc", {method = "OPTIONS"}))
            ngx.say(rx:dispatch("/aa/bb/cc", {method = "POST"}))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil
nil
handler /aa/bb/cc
true
