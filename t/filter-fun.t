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
                    paths = "/aa",
                    metadata = "metadata /aa",
                    filter_fun = function(vars)
                        ngx.log(ngx.WARN, "start to filter")
                        return vars['arg_k'] == 'v'
                    end
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
            ngx.say(rx:match("/aa", {}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- error_log
start to filter
--- response_body
metadata /aa
metadata /aa



=== TEST 2: not hit
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    filter_fun = function(vars)
                        ngx.log(ngx.WARN, "start to filter")
                        return vars['arg_k'] == 'v'
                    end
                }
            })

            ngx.say(rx:match("/aa", {vars = ngx.var}))
            ngx.say(rx:match("/aa", {}))
        }
    }
--- request
GET /t?k=not-hit
--- no_error_log
[error]
--- error_log
start to filter
--- response_body
nil
nil



=== TEST 3: match(path, opts)
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = ngx.var}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    metadata = "metadata /aa",
                    filter_fun = function(vars, opt, ...)
                        ngx.log(ngx.WARN, "start to filter, opt: ", opts == opt)
                        return vars['arg_k'] == 'v'
                    end
                }
            })

            ngx.say(rx:match("/aa", opts))
            ngx.say(rx:match("/aa", {}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- error_log
start to filter, opt: true
start to filter, opt: false
--- response_body
metadata /aa
metadata /aa



=== TEST 4: dispatch(path, opt, ...)
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = ngx.var}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    filter_fun = function(vars, opt, ...)
                        ngx.log(ngx.WARN, "start to filter, opt: ", opt == opts)
                        return vars['arg_k'] == 'v'
                    end,
                    handler = function (...)
                        ngx.say("handler /aa")
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa", opts))
            ngx.say(rx:dispatch("/aa", {}))
        }
    }
--- request
GET /t?k=v
--- no_error_log
[error]
--- error_log
start to filter, opt: true
start to filter, opt: false
--- response_body
handler /aa
true
handler /aa
true



=== TEST 5: dispatch(path, opt, ...) with nil arg
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = ngx.var}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = "/aa",
                    filter_fun = function(vars, opt, a, b, c)
                        ngx.log(ngx.WARN, "get arguments: ", a, ",", b, ",", c)
                        return true
                    end,
                    handler = function (...)
                        ngx.say("handler /aa")
                    end,
                }
            })

            ngx.say(rx:dispatch("/aa", opts, 1, nil, 3))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- error_log
get arguments: 1,nil,3
--- response_body
handler /aa
true
