use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: hello, world

This is just a simple demonstration of the 

echo directive provided by ngx_http_echo_module.

--- config

 location /t {
     content_by_lua_block {
        local radix = require("resty.radixtree")
        local rx = radix.new({
            {
                paths = {"/aa", "/bb*", "/name/:name/*other"},
                hosts = {"*.bar.com", "foo.com"},
                methods = {"GET", "POST", "PUT"},
                remote_addrs = {"127.0.0.1","192.168.0.0/16",
                                "::1", "fe80::/32"},
                vars = {
                    {"arg_name", "==", "json"},
                    {"arg_weight", ">", 10},
                },
                filter_fun = function(vars, opts)
                    return vars["arg_name"] == "json"
                end,

                metadata = "metadata /bb",
            }
        })

        -- try to match
        local opts = {
            host = "foo.com",
            method = "GET",
            remote_addr = "127.0.0.1",
            vars = ngx.var,
        }
        ngx.say(rx:match("/aa", opts))

     }
 }



--- request

GET /t?name=json&weight=20

--- response_body
 
metadata /bb

--- error_code: 200
