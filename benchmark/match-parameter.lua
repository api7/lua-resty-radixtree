local radix = require("resty.radixtree")
local route_count = 1000 * 100
local match_times = 1000 * 1000 * 10

local routes = {}
for i = 1, route_count do
    routes[i] = {paths = {"/user" .. i .. "/:name"}, metadata = i}
end

local rx = radix.new(routes)

ngx.update_time()
local start_time = ngx.now()

local res
local path = "/user1/gordon"
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
ngx.say("each time  : ", used_time * 1000 * 1000 / match_times, " ns")
