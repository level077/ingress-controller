local m = require "lua-resty-ingress-etcd.ingress"
local e  = require "lua-resty-endpoint-etcd.endpoint"
local s = require "lua-resty-service-etcd.service"
m.init()
e.init()
s.init()
