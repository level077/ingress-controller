local etcd = require "lua-resty-service-etcd.etcd"
local service_config = require "lua-resty-config.config"
local _M = {}
local conf = service_config.service_conf
local handle
function _M.init()
	handle = etcd:new(conf)
	local ok, err = handle:init()
	if not ok then
		return nil, err
	end
	return 1
end

function _M.get_hash_method(name)
	return handle:get_hash_method(name)
end

function _M.status()
	return handle:status()
end

return _M
