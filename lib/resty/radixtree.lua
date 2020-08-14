-- https://github.com/api7/lua-resty-radixtree
--
-- Copyright 2019-2020 Shenzhen ZhiLiu Technology Co., Ltd.
-- https://www.apiseven.com
--
-- See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The owner licenses this file to You under the Apache License, Version 2.0;
-- you may not use this file except in compliance with
-- the License. You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local ipmatcher   = require("resty.ipmatcher")
local base        = require("resty.core.base")
local clear_tab   = require("table.clear")
local clone_tab   = require("table.clone")
local lrucache    = require("resty.lrucache")
local bit         = require("bit")
local ngx         = ngx
local table       = table
local new_tab     = base.new_tab
local tonumber    = tonumber
local ipairs      = ipairs
local ffi         = require("ffi")
local ffi_cast    = ffi.cast
local ffi_cdef    = ffi.cdef
local insert_tab  = table.insert
local string      = string
local io          = io
local package     = package
local getmetatable=getmetatable
local setmetatable=setmetatable
local type        = type
local error       = error
local newproxy    = newproxy
local cur_level   = ngx.config.subsystem == "http" and
                    require("ngx.errlog").get_sys_filter_level()
local ngx_var     = ngx.var
local re_find     = ngx.re.find
local re_match    = ngx.re.match
local sort_tab    = table.sort
local ngx_re      = require("ngx.re")
local ngx_null    = ngx.null
local empty_table = {}
local str_find    = string.find


setmetatable(empty_table, {__newindex = function()
    error("empty_table can not be changed")
end})


local function load_shared_lib(so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match
    local io_open = io.open
    local io_close = io.close

    local cpath = package.cpath
    local tried_paths = new_tab(32, 0)
    local i = 1

    for k, _ in string_gmatch(cpath, "[^;]+") do
        local fpath = string_match(k, "(.*/)")
        fpath = fpath .. so_name
        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io_open(fpath)
        if f ~= nil then
            io_close(f)
            return ffi.load(fpath)
        end
        tried_paths[i] = fpath
        i = i + 1
    end

    return nil, tried_paths
end


local lib_name = "librestyradixtree.so"
if ffi.os == "OSX" then
    lib_name = "librestyradixtree.dylib"
end


local radix, tried_paths = load_shared_lib(lib_name)
if not radix then
    tried_paths[#tried_paths + 1] = 'tried above paths but can not load '
                                    .. lib_name
    error(table.concat(tried_paths, '\r\n', 1, #tried_paths))
end


ffi_cdef[[
    void *radix_tree_new();
    int radix_tree_destroy(void *t);
    int radix_tree_insert(void *t, const unsigned char *buf, size_t len,
        int idx);
    void *radix_tree_find(void *t, const unsigned char *buf, size_t len);
    void *radix_tree_search(void *t, void *it, const unsigned char *buf,
        size_t len);
    int radix_tree_pcre(void *it, const unsigned char *buf, size_t len);
    int radix_tree_stop(void *it);

    void *radix_tree_new_it(void *t);
]]


local METHODS = {}
for i, name in ipairs({"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD",
                       "OPTIONS", "CONNECT", "TRACE"}) do
    METHODS[name] = bit.lshift(1, i - 1)
    -- ngx.log(ngx.WARN, "name: ", name, " val: ", METHODS[name])
end


local _M = { _VERSION = 1.7 }


-- only work under lua51 or luajit
local function setmt__gc(t, mt)
    local prox = newproxy(true)
    getmetatable(prox).__gc = function() mt.__gc(t) end
    t[prox] = true
    return setmetatable(t, mt)
end


local function gc_free(self)
    -- if ngx.worker.exiting() then
    --     return
    -- end

    self:free()
end


    local ngx_log = ngx.log
    local ngx_INFO = ngx.INFO
local function log_info(...)
    if cur_level and ngx_INFO > cur_level then
        return
    end

    return ngx_log(ngx_INFO, ...)
end


local mt = { __index = _M, __gc = gc_free }


local function sort_route(route_a, route_b)
    return (route_a.priority or 0) > (route_b.priority or 0)
end


local function insert_route(self, opts)
    local path = opts.path
    opts = clone_tab(opts)

    if not self.disable_path_cache_opt
       and opts.path_op == '=' then

        if not self.hash_path[path] then
            self.hash_path[path] = {opts}
        else
            insert_tab(self.hash_path[path], opts)
        end

        sort_tab(self.hash_path[path], sort_route)
        return true
    end

    local data_idx = radix.radix_tree_find(self.tree, path, #path)
    if data_idx then
        local idx = tonumber(ffi_cast('intptr_t', data_idx))
        local routes = self.match_data[idx]
        if routes and routes[1].path == path then
            insert_tab(routes, opts)
            sort_tab(routes, sort_route)
            return true
        end
    end

    self.match_data_index = self.match_data_index + 1
    self.match_data[self.match_data_index] = {opts}

    radix.radix_tree_insert(self.tree, path, #path, self.match_data_index)
    log_info("insert route path: ", path, " dataprt: ", self.match_data_index)
    return true
end


local function parse_remote_addr(route_remote_addrs)
    if not route_remote_addrs then
        return
    end

    if type(route_remote_addrs) == "string" then
        route_remote_addrs = {route_remote_addrs}
    end

    local ip_ins, err = ipmatcher.new(route_remote_addrs)
    if not ip_ins then
        return nil, err
    end

    return ip_ins
end


local pre_insert_route
do
    local route_opts = {}

function pre_insert_route(self, path, route)
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    if type(route.metadata) == "nil" and type(route.handler) == "nil" then
        error("missing argument metadata or handler", 2)
    end

    if route.vars then
        if type(route.vars) ~= "table" then
            error("invalid argument vars", 2)
        end
    end

    local method  = route.methods
    local bit_methods
    if type(method) ~= "table" then
        bit_methods = method and METHODS[method] or 0

    else
        bit_methods = 0
        for _, m in ipairs(method) do
            bit_methods = bit.bor(bit_methods, METHODS[m])
        end
    end

    clear_tab(route_opts)

    local hosts = route.hosts
    if type(hosts) == "table" and #hosts > 0 then
        route_opts.hosts = {}
        for _, h in ipairs(hosts) do
            local is_wildcard = false
            if h and h:sub(1, 1) == '*' then
                is_wildcard = true
                h = h:sub(2):reverse()
            else
                h = h:reverse()
            end

            insert_tab(route_opts.hosts, is_wildcard)
            insert_tab(route_opts.hosts, h)
        end

    elseif type(hosts) == "string" then
        local is_wildcard = false
        local host = hosts
        if host:sub(1, 1) == '*' then
            is_wildcard = true
            host = host:sub(2):reverse()
        else
            host = host:reverse()
        end

        route_opts.hosts = {is_wildcard, host}
    end

    route_opts.path_org = path
    route_opts.param = false

    local pos = str_find(path, ':', 1, true)
    if pos then
        path = path:sub(1, pos - 1)
        route_opts.path_op = "<="
        route_opts.path = path
        route_opts.param = true

    else
        pos = str_find(path, '*', 1, true)
        if pos then
            if pos ~= #path then
                route_opts.param = true
            end
            path = path:sub(1, pos - 1)
            route_opts.path_op = "<="
        else
            route_opts.path_op = "="
        end
        route_opts.path = path
    end

    log_info("path: ", route_opts.path, " operator: ", route_opts.path_op)

    route_opts.metadata = route.metadata
    route_opts.handler  = route.handler
    route_opts.method   = bit_methods
    route_opts.vars     = route.vars
    route_opts.filter_fun   = route.filter_fun
    route_opts.priority = route.priority or 0

    local err
    local remote_addrs = route.remote_addrs
    route_opts.matcher_ins, err = parse_remote_addr(remote_addrs)
    if err then
        error("invalid IP address: " .. err, 2)
    end

    insert_route(self, route_opts)
end

end -- do


function _M.new(routes)
    if not routes then
        return nil, "missing argument route"
    end

    local route_n = #routes

    local tree = radix.radix_tree_new()
    local tree_it = radix.radix_tree_new_it(tree)
    if tree_it == nil then
        error("failed to new radixtree iterator")
    end

    local self = setmt__gc({
            tree = tree,
            tree_it = tree_it,
            match_data_index = 0,
            match_data = new_tab(#routes, 0),
            hash_path = new_tab(0, #routes),
        }, mt)

    -- register routes
    for i = 1, route_n do
        local route = routes[i]
        local paths = route.paths
        if type(paths) == "string" then
            pre_insert_route(self, paths, route)

        else
            for _, path in ipairs(paths) do
                pre_insert_route(self, path, route)
            end
        end
    end

    return self
end


function _M.free(self)
    local it = self.tree_it
    if it then
        radix.radix_tree_stop(it)
        ffi.C.free(it)
        self.tree_it = nil
    end

    if self.tree then
        radix.radix_tree_destroy(self.tree)
        self.tree = nil
    end

    return
end


local function match_host(route_host_is_wildcard, route_host, request_host)
    if type(request_host) ~= "string" or #route_host > #request_host then
        return false
    end

    if not route_host_is_wildcard then
        return route_host == request_host
    end

    local i = request_host:find(route_host, 1, true)
    if i ~= 1 then
        return false
    end

    return true
end


local tmp = {}
local lru_pat, err = lrucache.new(1000)
if not lru_pat then
    error("failed to generate new lru object: " .. err)
end

local function fetch_pat(path)
    local pat = lru_pat:get(path)
    if pat then
        return pat[1], pat[2]   -- pat, names
    end

    clear_tab(tmp)
    local res = ngx_re.split(path, "/", tmp)
    if not res then
        return false
    end

    local names = {}
    for i, item in ipairs(res) do
        local first_byte = item:byte(1, 1)
        if first_byte == string.byte(":") then
            table.insert(names, res[i]:sub(2))
            res[i] = [=[([\w\-_\%]+)]=]

        elseif first_byte == string.byte("*") then
            local name = res[i]:sub(2)
            if name == "" then
                name = ":ext"
            end
            table.insert(names, name)
            res[i] = [=[(.*)]=]
        end
    end

    pat = table.concat(res, [[\/]])
    lru_pat:set(path, {pat, names}, 60 * 60)
    return pat, names
end

local function compare_param(req_path, route, opts)
    if not opts.matched and not route.param then
        return true
    end

    local pat, names = fetch_pat(route.path_org)
    log_info("pcre pat: ", pat)
    local m = re_match(req_path, pat, "jo")
    if not m then
        return false
    end

    if not opts.matched then
        return true
    end

    for i, v in ipairs(m) do
        local name = names[i]
        if name and v then
            opts.matched[name] = v
        end
    end
    return true
end

local function in_array(l_v, r_v)
        if type(r_v) == "table" then
            for _,v in ipairs(r_v) do
                if v == l_v then
                    return true
                end
            end
        end
        return false
end

local compare_funcs = {
    ["=="] = function (l_v, r_v)
        if type(r_v) == "number" then
            l_v = tonumber(l_v)
            if not l_v then
                return false
            end
        end
        return l_v == r_v
    end,
    ["~="] = function (l_v, r_v)
        return l_v ~= r_v
    end,
    [">"] = function (l_v, r_v)
        l_v = tonumber(l_v)
        r_v = tonumber(r_v)
        if not l_v or not r_v then
            return false
        end
        return l_v > r_v
    end,
    ["<"] = function (l_v, r_v)
        l_v = tonumber(l_v)
        r_v = tonumber(r_v)
        if not l_v or not r_v then
            return false
        end
        return l_v < r_v
    end,
    ["~~"] = function (l_v, r_v)
        local from = re_find(l_v, r_v, "jo")
        if from then
            return true
        end
        return false
    end,
    ["IN"] = in_array,
    ["in"] = in_array,
}


local function compare_val(l_v, op, r_v, opts)
    if r_v == ngx_null then
        r_v = nil
    end

    local com_fun = compare_funcs[op or "=="]
    if not com_fun then
        return false
    end
    return com_fun(l_v, r_v, opts)
end


local function match_route_opts(route, opts, ...)
    local method = opts.method
    local opts_matched_exists = (opts.matched ~= nil)
    if route.method ~= 0 then
        if not method or type(METHODS[method]) ~= "number" or
           bit.band(route.method, METHODS[method]) == 0 then
            return false
        end
    end

    if opts_matched_exists then
        opts.matched._method = method
    end

    local matcher_ins = route.matcher_ins
    if matcher_ins then
        local ok, err = matcher_ins:match(opts.remote_addr)
        if err then
            log_info("failed to match ip: ", err)
            return false
        end
        if not ok then
            return false
        end
    end

    -- log_info("route.hosts: ", type(route.hosts))
    if route.hosts then
        local matched = false

        if opts.host and not opts.host_reversed then
            opts.host_reversed = opts.host:reverse()
        end

        local hosts = route.hosts
        local reverse_host = opts.host_reversed
        if reverse_host then
            for i = 1, #hosts, 2 do
                if match_host(hosts[i], hosts[i + 1], reverse_host) then
                    if opts_matched_exists then
                        if hosts[i] then
                            opts.matched._host = (hosts[i + 1] .. "*"):reverse()
                        else
                            opts.matched._host = hosts[i + 1]:reverse()
                        end
                    end
                    matched = true
                    break
                end
            end
        end

        log_info("hosts match: ", matched)
        if not matched then
            return false
        end
    end

    if route.vars then
        local vars = opts.vars or ngx_var
        if type(vars) ~= "table" then
            return false
        end

        for _, route_var in ipairs(route.vars) do
            local l_v, op, r_v = route_var[1], route_var[2], route_var[3]
            l_v = vars[l_v]

            if not compare_val(l_v, op, r_v, opts) then
                return false
            end
        end
    end

    if route.filter_fun then
        if not route.filter_fun(opts.vars or ngx_var, opts, ...) then
            return false
        end
    end

    return true
end


local function _match_from_routes(routes, path, opts, ...)
    local opts_matched_exists = (opts.matched ~= nil)
    for _, route in ipairs(routes) do
        if route.path_op == "=" then
            if route.path == path then
                if match_route_opts(route, opts, ...) then
                    if opts_matched_exists then
                        opts.matched._path = path
                    end
                    return route
                end
            end
            goto continue
        end

        if match_route_opts(route, opts, ...) then
            -- log_info("matched route: ", require("cjson").encode(route))
            -- log_info("matched path: ", path)
            if compare_param(path, route, opts) then
                if opts_matched_exists then
                    opts.matched._path = route.path_org
                end
                return route
            end
        end

        ::continue::
    end

    return nil
end


local function match_route(self, path, opts, ...)
    if opts.matched then
        clear_tab(opts.matched)
    end

    local routes = self.hash_path[path]
    local opts_matched_exists = (opts.matched ~= nil)
    if routes then
        for _, route in ipairs(routes) do
            if match_route_opts(route, opts, ...) then
                if opts_matched_exists then
                    opts.matched._path = path
                end
                return route
            end
        end
    end

    local it = radix.radix_tree_search(self.tree, self.tree_it, path, #path)
    if not it then
        return nil, "failed to match"
    end

    while true do
        local idx = radix.radix_tree_pcre(it, path, #path)
        if idx <= 0 then
            break
        end

        routes = self.match_data[idx]
        if routes then
            local route = _match_from_routes(routes, path, opts, ...)
            if route then
                return route
            end
        end
    end

    return nil
end

function _M.match(self, path, opts)
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    local route, err = match_route(self, path, opts or empty_table)
    if not route then
        if err then
            return nil, err
        end
        return nil
    end

    return route.metadata
end


function _M.dispatch(self, path, opts, ...)
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    local route, err = match_route(self, path, opts or empty_table, ...)
    if not route then
        if err then
            return nil, err
        end
        return nil
    end

    local handler = route.handler
    if not handler or type(handler) ~= "function" then
        return nil, "missing handler"
    end

    handler(...)
    return true
end


return _M
