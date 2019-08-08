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
    void *radix_tree_search(void *t, const unsigned char *buf, size_t len);
    void *radix_tree_pcre(void *it, const unsigned char *buf, size_t len);
    void *radix_tree_next(void *it, const unsigned char *buf, size_t len);
    int radix_tree_stop(void *it);
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


local mt = { __index = _M, __gc = gc_free }


local function insert_route(self, opts)
    local path    = opts.path
    local metadata = opts.metadata

    if type(path) ~= "string" then
        error("invalid argument path")
    end

    if type(metadata) == "nil" then
        error("invalid argument handler")
    end

    self.match_data_index = self.match_data_index + 1
    opts = clone_tab(opts)
    self.match_data[self.match_data_index] = opts

    local dataptr = ffi_cast('void *', self.match_data_index)
    radix.radix_tree_insert(self.tree, path, #path, dataptr)
    -- ngx.log(ngx.INFO, "insert route: ", path)

    insert_tab(self.cached_routes_opt, opts)
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
            cached_routes_opt = new_tab(#routes, 0),
        }, mt)

    -- register routes
    for i = 1, route_n do
        local route = routes[i]

        if type(route.path) ~= "string" then
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
        if host and host:sub(1, 1) == '*' then
            route_opts.host_is_wildcard = true
            route_opts.host_wildcard = host:sub(2):reverse()
        else
            route_opts.host = host
        end

        route_opts.path    = route.path
        route_opts.metadata = route.metadata
        route_opts.method  = bit_methods
        route_opts.host    = route.host

        if route.remote_addr then
            local idx = find_str(route.remote_addr, "/", 1, true)
            if idx then
                route_opts.remote_addr  = str_sub(route.remote_addr, 1, idx - 1)
                route_opts.remote_addr_bits = str_sub(route.remote_addr,
                                                      idx + 1)

            else
                route_opts.remote_addr = route.remote_addr
                route_opts.remote_addr_bits = 32
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


local function match_route_opts(route, opts)
    local method = opts.method
    if route.method ~= 0 and
        bit.band(route.method, METHODS[method]) == 0 then
        return false
    end

    if route.host then
        if #route.host > #opts.host then
            return false
        end

        if route.host_is_wildcard then
            local i = opts.host:reverse():find(route.host_wildcard, 1, true)
            if i ~= 1 then
                return false
            end

        elseif route.host ~= opts.host then
            return false
        end
    end

    return true
end


local function sort_route(l, r)
    ngx.log(ngx.WARN, require("cjson").encode(l))
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
        if data_idx == nil then
            break
        end

        local idx = tonumber(ffi_cast('intptr_t', data_idx))
        local route = self.match_data[idx]
        if route then
            insert_tab(matched_routes, route)
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
