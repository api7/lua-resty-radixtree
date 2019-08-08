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
                    metadata = "metadata /aaa",
                },
                {
                    path = "/dd",
                    metadata = "metadata /dd",
                },
                {
                    path = "/dd/aa",
                    metadata = "metadata /dd/aa",
                },
                {
                    path = "/dd/ee",
                    metadata = "metadata /dd/ee",
                },
                {
                    path = "/ff/gg",
                    metadata = "metadata /ff/gg",
                }
            })

            local metadata = rx:match("/dd/ee/jj/kk")
            ngx.say(metadata)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
metadata /dd/ee
