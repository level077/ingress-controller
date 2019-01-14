local b = require "ngx.balancer"
local ingress = require "lua-resty-ingress-etcd.ingress"
local host = ngx.var.host
local uri = ngx.var.uri
local ingress_id = ngx.ctx.ingress
local server, err = ingress.find(host,uri,ingress_id)
if not server then
	ngx.log(ngx.ERR,err)
	return ngx.exit(500)
end
local ok, err = b.set_current_peer(server)
if not ok then
	ngx.log(ngx.ERR,err)
end
