local endpoint = require "lua-resty-service-etcd.service"
ngx.say(endpoint.status())
