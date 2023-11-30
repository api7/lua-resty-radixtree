# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: test add
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

        ngx.log(ngx.ERR, "check:", add_opts["hosts"][1], add_opts["paths"][1], opts["host"])
        ngx.say(rx:match("/abc/123456aa", opts))
     }
 }
--- error_log
check:*.love.com/abc/123*abc.love.com
--- request
GET /t?name=json&weight=20
--- response_body
metadata add route succeed.
--- error_code: 200



=== TEST 2: test host and port
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = {http_host = "127.0.0.1:9080"}, host = "127.0.0.1"}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    hosts = {"127.0.0.1:9080"},
                    handler = function (ctx)
                        ngx.say("pass")
                    end
                }
            })
            ngx.say(rx:dispatch("/aa", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
pass
true



=== TEST 3: test domain and port
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = {http_host = "www.foo.com:9080"}, host = "www.foo.com"}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    hosts = "www.foo.com:9080",
                    handler = function (ctx)
                        ngx.say("pass")
                    end
                }
            })
            ngx.say(rx:dispatch("/aa", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
pass
true



=== TEST 4: match failed
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = {http_host = "127.0.0.1"}, host = "127.0.0.1"}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    hosts = "127.0.0.1:9080",
                    handler = function (ctx)
                        ngx.say("pass")
                    end
                }
            })
            ngx.say(rx:dispatch("/aa", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
nil



=== TEST 5: match success
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = {http_host = "127.0.0.1:9080"}, host = "127.0.0.1"}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    hosts = "127.0.0.1",
                    handler = function (ctx)
                        ngx.say("pass")
                    end
                }
            })
            ngx.say(rx:dispatch("/aa", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
pass
true



=== TEST 6: match many host
--- config
    location /t {
        content_by_lua_block {
            local opts = {vars = {http_host = "127.0.0.1:9980"}, host = "127.0.0.1"}
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    hosts = {"www.foo.com:9080", "127.0.0.1:9991", "www.bar.com:9200", "127.0.0.1"},
                    handler = function (ctx)
                        ngx.say("pass")
                    end
                }
            })
            ngx.say(rx:dispatch("/aa", opts))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
pass
true
