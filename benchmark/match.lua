local radix = require("resty.radixtree")

local routes = {}
for i = 1, 1000 * 100 do
    routes[i] = {paths = {"/" .. ngx.md5(i) .. "/*"}, metadata = i}
end

local rx = radix.new(routes)

local res
local uri = "/" .. ngx.md5(500) .. "/a"
for _ = 1, 1000 * 1000 do
    res = rx:match(uri)
end

ngx.say(res)
