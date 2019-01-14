local etcd = require "lua-resty-endpoint-etcd.etcd"
local ep_config = require "lua-resty-config.config"
local _M = {}
local conf = ep_config.endpoint_conf
local handle
function _M.init()
	handle = etcd:new(conf)
	local ok, err = handle:init()
	if not ok then
		return nil, err
	end
	return 1
end

function _M.find(name,key,hash_method)
	return handle:find(name,key,hash_method)
end

function _M.status()
	return handle:status()
end

return _M
