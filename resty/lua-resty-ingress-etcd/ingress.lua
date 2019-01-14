local etcd = require "lua-resty-ingress-etcd.etcd"
local ingress_config = require "lua-resty-config.config"
local endpoint = require "lua-resty-endpoint-etcd.endpoint"
local sv = require "lua-resty-service-etcd.service"
local conf = ingress_config.ingress_conf
local _M = {}
local handle
function _M.init()
	handle = etcd:new(conf)
	local ok, err = handle:init()
	if not ok then
		return nil, err
	end
	return 1
end

function _M.find(host,uri,key)
	local service, err = handle:getsvc(host,uri)
	if not service then
		return nil, err
	end
	local hash_method = sv.get_hash_method(service)
	return endpoint.find(service,key,hash_method)
end

function _M.status()
	return handle:status()
end

return _M
