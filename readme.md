Description
==============
使用openresty完成的kubernetes的ingress controller。仅适合etcd的v2版本。

Usage
==============
nginx.conf
```
lua_code_cache on;
lua_package_path "/usr/local/nginx/resty/?.lua;;";
lua_package_cpath "/usr/local/nginx/resty/?.so;;";
init_worker_by_lua_file "/usr/local/nginx/resty/init.lua";
access_by_lua_file "/usr/local/nginx/resty/access.lua";
upstream etcd_pool {
  server 0.0.0.1;
  balancer_by_lua_file "/usr/local/nginx/resty/balancer.lua";
  keepalive 60;
}

server {
  listen 80 default;
  server_name _;
  location / {
    proxy_pass http://etcd_pool;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }

server {
  listen 80;
  server_name example.com;
  location /status {
    content_by_lua_file "/usr/local/nginx/resty/lua-resty-ingress-etcd/status.lua";
  }
  #查看endpoints
  location /ep_status {
    content_by_lua_file "/usr/local/nginx/resty/lua-resty-endpoint-etcd/status.lua";
  }
  #查看service
  location /service_status {
    content_by_lua_file "/usr/local/nginx/resty/lua-resty-service-etcd/status.lua";
  }
}

```

Note
=======
- etcd的配置在resty/lua-resty-config/config.lua, 写死了etcd的IP地址
- chash的配置可以在Service的annotations里指定，如：
  ```
    apiVersion: v1
    kind: Service
    metadata:
      name: test
      annotations:
        affinity: chash
    spec:
      ports:
      - port: 8080
        protocol: TCP
      selector:
        app: test
  ```
