local ingress = ngx.var.cookie_ingress
local uuid = require "lua-resty-uuid.uuid"
if not ingress then
	local uid = uuid.generate()
	ngx.header['Set-Cookie'] = {'ingress='..uid..';path=/;HttpOnly'}
	ngx.ctx.ingress = uid
else
	ngx.ctx.ingress = ingress
end
