local endpoint = require "lua-resty-endpoint-etcd.endpoint"
ngx.say(endpoint.status())
