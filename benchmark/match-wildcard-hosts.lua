local radix = require("resty.radixtree")
local route_count = 1000 * 1
local match_times = 1000 * 50

local path = "/12345"
local routes = {}
for i = 1, route_count do
    routes[i] = {paths = {path}, priority = i, hosts = {"*." .. ngx.md5(i)}, metadata = i}
end

local rx = radix.new(routes)

ngx.update_time()
local start_time = ngx.now()

local res
local opts = {
    host = "1." .. ngx.md5(500),
}
for _ = 1, match_times do
    res = rx:match(path, opts)
end

ngx.update_time()
local used_time = ngx.now() - start_time
ngx.say("matched res: ", res)
ngx.say("route count: ", route_count)
ngx.say("match times: ", match_times)
ngx.say("time used  : ", used_time, " sec")
ngx.say("QPS        : ", math.floor(match_times / used_time))
