use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: multiple route (same priority)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    metadata = "metadata 1",
                },
                {
                    paths = {"/aa"},
                    metadata = "metadata 2",
                },
            })

            ngx.say(rx:match("/aa"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata 1



=== TEST 2: multiple route (different priority)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa"},
                    metadata = "metadata 1",
                    priority = 1,
                },
                {
                    paths = {"/aa"},
                    metadata = "metadata 2",
                    priority = 2,
                },
            })

            ngx.say(rx:match("/aa"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata 2



=== TEST 3: multiple route (same priority)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata 1",
                },
                {
                    paths = {"/aa*"},
                    metadata = "metadata 2",
                },
            })

            ngx.say(rx:match("/aa/bb"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata 1



=== TEST 4: multiple route (different priority)
--- config
    location /t {
        content_by_lua_block {
            local radix = require("resty.radixtree")
            local rx = radix.new({
                {
                    paths = {"/aa*"},
                    metadata = "metadata 1",
                },
                {
                    paths = {"/aa*"},
                    metadata = "metadata 2",
                    priority = 1,
                },
            })

            ngx.say(rx:match("/aa/bb"))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata 2
