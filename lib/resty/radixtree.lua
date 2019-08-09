-- Copyright (C) Yuansheng Wang

local base        = require("resty.core.base")
local clear_tab   = require("table.clear")
local clone_tab   = require("table.clone")
local bit         = require("bit")
local new_tab     = base.new_tab
local find_str    = string.find
local tonumber    = tonumber
local ipairs      = ipairs
local ffi         = require "ffi"
local ffi_cast    = ffi.cast
local ffi_cdef    = ffi.cdef
local ffi_new     = ffi.new
local insert_tab  = table.insert
local string      = string
local io          = io
local package     = package
local getmetatable=getmetatable
local setmetatable=setmetatable
local type        = type
local error       = error
local newproxy    = _G.newproxy
local str_sub     = string.sub
local sort_tab    = table.sort
local cur_level = ngx.config.subsystem == "http" and
                  require "ngx.errlog" .get_sys_filter_level()


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
        void *data);
    void *radix_tree_find(void *t, const unsigned char *buf, size_t len);
    void *radix_tree_search(void *t, const unsigned char *buf, size_t len);
    void *radix_tree_pcre(void *it, const unsigned char *buf, size_t len);
    void *radix_tree_next(void *it, const unsigned char *buf, size_t len);
    int radix_tree_stop(void *it);

    unsigned int inet_network(const char *cp);

    typedef struct {
        unsigned int   val;
        int            bit;
    } ip_addr_item;

    int is_valid_ipv4(const char *ipv4);
    int is_valid_ipv6(const char *ipv6);
    int parse_ipv6(const char *ipv6, ip_addr_item *addr_items);
]]


local METHODS = {
  GET     = 2,
  POST    = bit.lshift(2, 1),
  PUT     = bit.lshift(2, 2),
  DELETE  = bit.lshift(2, 3),
  PATCH   = bit.lshift(2, 4),
  HEAD    = bit.lshift(2, 5),
  OPTIONS = bit.lshift(2, 16),
}


local _M = { _VERSION = '0.01' }


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


local function insert_route(self, opts)
    local path    = opts.path
    opts = clone_tab(opts)

    local data_idx = radix.radix_tree_find(self.tree, path, #path)
    log_info("find: ", path, " matched: ", tostring(data_idx))
    if data_idx then
        local idx = tonumber(ffi_cast('intptr_t', data_idx))
        local routes = self.match_data[idx]
        if routes and routes[1].path == path then
            insert_tab(routes, opts)
            return
        end
    end

    self.match_data_index = self.match_data_index + 1
    self.match_data[self.match_data_index] = {opts}

    local dataptr = ffi_cast('void *', self.match_data_index)
    radix.radix_tree_insert(self.tree, path, #path, dataptr)
    log_info("insert route path: ", path, " dataprt: ", tostring(dataptr))
    return true
end

do
    local route_opts = {}
function _M.new(routes)
    if not routes then
        return nil, "missing argument route"
    end

    local route_n = #routes

    local self = setmt__gc({
            tree = radix.radix_tree_new(),
            match_data_index = 0,
            match_data = new_tab(#routes, 0),
        }, mt)

    -- register routes
    for i = 1, route_n do
        local route = routes[i]

        if type(route.path) ~= "string" and type(route.prefix_path) ~= "string" then
            error("invalid argument path", 2)
        end

        if type(route.metadata) == "nil" then
            error("missing argument metadata", 2)
        end

        local method  = route.method
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

        local host = route.host
        if type(host) == "table" and #host > 0 then
            route_opts.hosts = {}
            for _, h in ipairs(host) do
                local host_is_wildcard = false
                if h and h:sub(1, 1) == '*' then
                    host_is_wildcard = true
                    h = h:sub(2):reverse()
                end

                insert_tab(route_opts.hosts, host_is_wildcard)
                insert_tab(route_opts.hosts, h)
            end

        elseif type(host) == "string" then
            local host_is_wildcard = false
            if host and host:sub(1, 1) == '*' then
                host_is_wildcard = true
                host = host:sub(2):reverse()
            end

            route_opts.hosts = {host_is_wildcard, host}
        end

        local path = route.path
        local prefix_path = route.prefix_path
        if path and prefix_path then
            error("field `path` and `prefix_path` can not work together")
        end
        if not path and prefix_path then
            path = prefix_path
            route_opts.path_op = "<="
        else
            route_opts.path_op = "="
        end
        route_opts.path = path

        route_opts.metadata = route.metadata
        route_opts.method  = bit_methods

        if route.remote_addr then
            local remote_addr = route.remote_addr
            local remote_addr_bits

            local idx = find_str(remote_addr, "/", 1, true)
            if idx then
                remote_addr  = str_sub(remote_addr, 1, idx - 1)
                remote_addr_bits = str_sub(route.remote_addr, idx + 1)
                remote_addr_bits = tonumber(remote_addr_bits)
            end

            if radix.is_valid_ipv4(remote_addr) == 0 then
                route_opts.remote_addrs = {
                    radix.inet_network(remote_addr),
                    remote_addr_bits or 32,
                }

            elseif radix.is_valid_ipv6(remote_addr) == 0 then
                local ip_items = ffi_new("ip_addr_item[?]", 4)
                local ret = radix.parse_ipv6(remote_addr, ip_items)
                if ret ~= 0 then
                    error("failed to parse ipv6 address: " .. remote_addr)
                end

                route_opts.remote_addrs = new_tab(4, 0)
                remote_addr_bits = remote_addr_bits or 128
                for j = 1, 4 do
                    insert_tab(route_opts.remote_addrs, ip_items[j - 1].val)

                    if remote_addr_bits >= 32 then
                        insert_tab(route_opts.remote_addrs, 32)
                    elseif remote_addr_bits > 0 then
                        insert_tab(route_opts.remote_addrs, remote_addr_bits)
                    else
                        insert_tab(route_opts.remote_addrs, 0)
                    end

                    remote_addr_bits = remote_addr_bits - 32
                end

            else
                error("invalid ip address: " .. remote_addr)
            end
        end

        insert_route(self, route_opts)
    end

    return self
end

end -- do


function _M.free(self)
    if not self.tree then
        return
    end

    radix.radix_tree_destroy(self.tree)
    self.tree = nil
    return
end


local function match_host(route_host_is_wildcard, route_host, request_host)
    if #route_host > #request_host then
        return false
    end

    if not route_host_is_wildcard then
        return route_host == request_host
    end

    local i = request_host:reverse():find(route_host, 1, true)
    if i ~= 1 then
        return false
    end

    return true
end


local function match_route_opts(route, opts)
    local method = opts.method
    if route.method ~= 0 and
        bit.band(route.method, METHODS[method]) == 0 then
        return false
    end

    log_info("route.hosts: ", type(route.hosts))
    if route.hosts then
        local matched = false
        local hosts = route.hosts
        for i = 1, #route.hosts, 2 do
            if match_host(hosts[i], hosts[i + 1], opts.host) then
                matched = true
                break
            end
        end

        log_info("hosts match: ", matched)
        if not matched then
            return false
        end
    end

    local remote_addrs = route.remote_addrs
    if remote_addrs and #remote_addrs == 2 then
        if radix.is_valid_ipv4(opts.remote_addr) ~= 0 then
            return false
        end

        local route_addr_bits = 32 - remote_addrs[2]
        local remote_addr_inet = radix.inet_network(opts.remote_addr)
        if bit.rshift(remote_addrs[1], route_addr_bits)
            ~= bit.rshift(remote_addr_inet, route_addr_bits) then
            return false
        end

    elseif remote_addrs and #remote_addrs == 8 then
        if radix.is_valid_ipv6(opts.remote_addr) ~= 0 then
            return false
        end

        local ip_items = ffi_new("ip_addr_item[?]", 4)
        local ret = radix.parse_ipv6(opts.remote_addr, ip_items)
        if ret ~= 0 then
            error("failed to parse ipv6 address: " .. opts.remote_addr)
        end

        for i = 1, 4 do
            local route_addr_bits = 32 - remote_addrs[i * 2]
            local remote_addr_inet = ip_items[i - 1].val
            if bit.rshift(remote_addrs[i * 2 - 1], route_addr_bits)
                ~= bit.rshift(remote_addr_inet, route_addr_bits) then
                return false
            end
        end
    end

    return true
end


local function sort_route(l, r)
    return #l.path >= #r.path
end


    local matched_routes = {}
local function match_route(self, path, opts)
    local it = radix.radix_tree_search(self.tree, path, #path)
    if not it then
        return nil, "failed to match"
    end

    clear_tab(matched_routes)
    while true do
        local data_idx = radix.radix_tree_pcre(it, path, #path)
        log_info("path: ", path, " data_idx: ", tostring(data_idx))
        if data_idx == nil then
            break
        end

        local idx = tonumber(ffi_cast('intptr_t', data_idx))
        local routes = self.match_data[idx]
        -- log_info("route: ", require("cjson").encode(routes))
        if routes then
            for _, route in ipairs(routes) do
                if route.path_op == "=" then
                    if route.path == path then
                        insert_tab(matched_routes, route)
                        break
                    end
                else
                    insert_tab(matched_routes, route)
                end
            end
        end
    end

    radix.radix_tree_stop(it)

    if #matched_routes == 0 then
        return nil
    end

    sort_tab(matched_routes, sort_route)

    for _, route in ipairs(matched_routes) do
        if match_route_opts(route, opts) then
            return route.metadata
        end
    end

    return nil
end

    local empty_table = {}
function _M.match(self, path, opts)
    if type(path) ~= "string" then
        error("invalid argument path", 2)
    end

    local ok = match_route(self, path, opts or empty_table)
    return ok
end


return _M
