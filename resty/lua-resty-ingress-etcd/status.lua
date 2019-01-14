local ingress = require "lua-resty-ingress-etcd.ingress"
ngx.say(ingress.status())
