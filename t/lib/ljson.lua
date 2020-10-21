local new_tab  = require("table.new")
local isarray  = require("table.isarray")
local ngx_null = ngx.null
local tostring = tostring
local gsub     = string.gsub
local sort     = table.sort
local pairs    = pairs
local ipairs   = ipairs
local concat   = table.concat
local type     = type

local metachars = {
    ['\t'] = '\\t',
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ['\r'] = '\\r',
    ['\n'] = '\\n',
}
local _M = {}


local function encode_str(s)
    return gsub(s, '["\\\r\n\t]', metachars)
end


local function encode(v)
    if v == nil or v == ngx_null then
        return "null"
    end

    local typ = type(v)
    if typ == 'string' then
        return '"' .. encode_str(v) .. '"'
    end

    if typ == 'number' or typ == 'boolean' then
        return tostring(v)
    end

    if typ == 'table' then
        local n = isarray(v)
        if n then
            local bits = new_tab(n, 0)
            for i, elem in ipairs(v) do
                bits[i] = encode(elem)
            end
            return "[" .. concat(bits, ",") .. "]"
        end

        local keys = {}
        local i = 0
        for key, _ in pairs(v) do
            i = i + 1
            keys[i] = key
        end
        sort(keys)

        local bits = new_tab(0, i)
        i = 0
        for _, key in ipairs(keys) do
            i = i + 1
            bits[i] = encode(key) .. ":" .. encode(v[key])
        end
        return "{" .. concat(bits, ",") .. "}"
    end

    return '"<' .. typ .. '>"'
end
_M.encode = encode


return _M
