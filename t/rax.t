# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::RX 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: not found
--- config
    location /t {
        content_by_lua_block {
            local ffi = require("ffi")
            local radix = require("resty.radixtree")
            local radix_symbols = radix._symbols

            local tree = radix_symbols.radix_tree_new()
            local foo = "foo"
            local data_idx = radix_symbols.radix_tree_find(tree, foo, #foo)

            local idx = tonumber(ffi.cast('intptr_t', data_idx))
            ngx.say(idx)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
0

=== TEST 2: rax not init
--- config
    location /t {
        content_by_lua_block {
            local ffi = require("ffi")
            local radix = require("resty.radixtree")
            local radix_symbols = radix._symbols

            local tree = nil
            local foo = "foo"
            local data_idx = radix_symbols.radix_tree_find(tree, foo, #foo)

            local idx = tonumber(ffi.cast('intptr_t', data_idx))
            ngx.say(idx)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
0
