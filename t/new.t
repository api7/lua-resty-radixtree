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
                paths = {"/aa", "/bb*"},
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
        local opts_check = {
            host = "foo.com",
            method = "GET",
            remote_addr = "127.0.0.1",
            vars = ngx.var,
        }
        ngx.say(rx:match("/aa", opts_check))
     }
 }
--- request
GET /t?name=json&weight=20
--- response_body
metadata /bb
