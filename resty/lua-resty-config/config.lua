local _M = {}

_M.ingress_conf = {
	etcd_host = '192.168.1.1',
	etcd_port = 2379,
	etcd_path = "/registry/ingress/namespace",
}

_M.endpoint_conf = {
	etcd_host = '192.168.1.1',
        etcd_port = 2379,
	etcd_path = "/registry/services/endpoints/namespace",
}

_M.service_conf = {
	etcd_host = '192.168.1.1',
        etcd_port = 2379,
        etcd_path = "/registry/services/specs/namespace",
}

return _M
