local radix = require("resty.radixtree")
local route_count = 1000 * 100
local match_times = 1000 * 1000

local routes = {}
for i = 1, route_count do
    routes[i] = {paths = {"/" .. ngx.md5(i) .. "/*"}, metadata = i}
end

local rx = radix.new(routes)
ngx.say("case 1: route matched ")
ngx.update_time()
local start_time = ngx.now()

local res
local path = "/" .. ngx.md5(500) .. "/a"
for _ = 1, match_times do
    res = rx:match(path)
end

ngx.update_time()
local used_time = ngx.now() - start_time
ngx.say("matched res: ", res)
ngx.say("route count: ", route_count)
ngx.say("match times: ", match_times)
ngx.say("time used  : ", used_time, " sec")
ngx.say("QPS        : ", math.floor(match_times / used_time))

ngx.say("=================")
ngx.say("case 2: route not matched ")
ngx.update_time()
start_time = ngx.now()

path = "/" .. ngx.md5(route_count + 1) .. "/a"
for _ = 1, match_times do
    res = rx:match(path)
end

ngx.update_time()
local used_time = ngx.now() - start_time
ngx.say("matched res: ", res)
ngx.say("route count: ", route_count)
ngx.say("match times: ", match_times)
ngx.say("time used  : ", used_time, " sec")
ngx.say("QPS        : ", math.floor(match_times / used_time))
