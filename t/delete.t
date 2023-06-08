# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: test delete
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
        --ngx.say(rx:match("/aa", opts))
        
        --step 1. add route api
        local router_opts = {
            no_param_match = true
        }

        local add_opts = {
            id = "00000000000024216171",
            paths = {"/abc/123*", "/def"},
            hosts = {"*.love.com", "angel.com"},
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
            metadata = "metadata add route succeed.",
        }
        rx:add_route(add_opts, router_opts)

        local opts = {
            host = "abc.love.com",
            method = "GET",
            remote_addr = "127.0.0.1",
            vars = ngx.var,
        }
        --ngx.say(rx:match("/abc/123456aa", opts))

        --step 2. update route api
        local update_opts = {
            id = "00000000000024216171",
            paths = {"/nigolas/cage*", "/tom/cruise"},
            hosts = {"*.angel.city.com", "impossible.mission.com"},
            methods = {"GET", "POST", "PUT"},
            remote_addrs = {"127.0.0.1","192.168.0.0/16",
                            "::1", "fe80::/32"},
            vars = {
                {"arg_name", "==", "cinema"},
                {"arg_weight", "<", 60}, 
            },
            filter_fun = function(vars, opts)
                return vars["arg_name"] == "cinema"
            end,
            metadata = "metadata update route succeed.",
        }

        rx:update_route(add_opts, update_opts, router_opts)

        local opts = {
            host = "impossible.mission.com",
            method = "GET",
            remote_addr = "127.0.0.1",
            vars = ngx.var,
        }
        --ngx.say(rx:match("/nigolas/cage/oscars", opts))

        --step 3. 
        rx:delete_route(update_opts, router_opts)
        ngx.say(rx:match("/nigolas/cage/oscars", opts))
     }
 }
--- request
GET /t?name=cinema&weight=20
--- response_body
nil
--- error_code: 200
