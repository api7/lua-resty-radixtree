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
                    path = "/aa",
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
                    path = "/aa",
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
