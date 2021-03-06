local http = require "lua-resty-http.http"
local json = require "cjson"
local ngx_timer_at = ngx.timer.at
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_INFO = ngx.INFO
local ngx_worker_exiting = ngx.worker.exiting
local ngx_match = ngx.re.match
local ngx_sleep = ngx.sleep

local _M = {}
local mt = { __index = _M }
_M.op_hash = {}

local function log(...)
    ngx_log(ngx_ERR, ...)
end

local function log_error(...)
    ngx_log(ngx_ERR, ...)
end

local function log_info(...)
    ngx_log(ngx_INFO, ...)
end

local function request_etcd(conf,param)
        if type(param) ~= "table" then
                return nil, "param must be table"
        end
        local c = http:new()
        c:set_timeout(20000)
        c:connect(conf.etcd_host, conf.etcd_port)
        local res, err = c:request(param)
        if not err then
                local body, err = res:read_body()
                if not err then
                        local all = json.decode(body)
                        if all.errorCode then
                                return nil, all.errorCode
                        else
                                return all.node.value or true
                        end
                else
                        return nil, err
                end
        else
                return nil, err
        end
end

local function convert(self,key)
	local name = self[key]["metadata"]["name"]
	local annotations = self[key]["metadata"]["annotations"]
	local affinity = "rr"
	if annotations then
		affinity = annotations["affinity"] or "rr"
		if affinity ~= "chash" and affinity ~= "rr" then
			affinity = "rr"
		end
	end
	self[name] = affinity
end

local function convertall(self)
        for k,v in pairs(self)
        do
                local m, err = ngx_match(k,self["conf"]["etcd_path"],"jo")
                if m then
			convert(self,k)	
                end
        end
end

local function get_allkeys(self,key)
	local conf = self.conf
	local c = http:new()
	c:set_timeout(5000)
	local ok, err = c:connect(conf.etcd_host,conf.etcd_port)
	if not ok then
		log_error(err)
		ngx_sleep(5)
	end
	local url
	if not key then
		url = "/v2/keys" .. conf.etcd_path 
	else
		url = "/v2/keys" .. key 
	end
	local res, err = c:request({path = url, method = "GET"})
	if not err then
		local body, err = res:read_body()
		if not err then
			local all = json.decode(body)
			if not all.errorCode and all.node.nodes then
				for k,v in pairs(all.node.nodes) do
					if v.dir then
						get_allkeys(self,v.key)
					else
						self[v.key] = json.decode(v.value)
					end
				end
			end
		else
			return nil, err
		end
		self.version = res.headers["x-etcd-index"]
	else
		return nil, err
	end
	convertall(self)
	c:set_keepalive(5000,10)
	return 1
end

local function delete(self,key)
        local name = self[key]["metadata"]["name"]
	self[name] = nil
end

local function watch(premature, self, index)
    if premature then
        return
    end

    if ngx_worker_exiting() then
        return
    end

    local conf = self.conf

    local c = http:new()

    local nextIndex
    local url = "/v2/keys" .. conf.etcd_path

    if index == nil then
	get_allkeys(self)
	if self.version then
		nextIndex = self.version + 1
	end
    else
	c:set_timeout(120000)
    	local ok, err = c:connect(conf.etcd_host, conf.etcd_port)
	if not ok then
		log_error(err)
		ngx_sleep(5)
	end
        local s_url = url .. "?wait=true&recursive=true&waitIndex=" .. index
        local res, err = c:request({ path = s_url, method = "GET" })
        if not err then
            local body, err = res:read_body()
            if not err then
                local change = json.decode(body)
                if not change.errorCode then
                    local action = change.action
                    if not change.node.dir then
                        local ok, value = pcall(json.decode, change.node.value)
                        if action == "compareAndDelete" then
				delete(self,change.node.key)
				if self[change.node.key] then
					self[change.node.key] = nil
				end
                        elseif action == "compareAndSwap" or action == "create" then
				self[change.node.key] = value
				convert(self,change.node.key)
                        end
                    end
                    self.version = change.node.modifiedIndex
                    nextIndex = self.version + 1
                elseif change.errorCode == 401 then
                    nextIndex = nil
                end
            elseif err == "timeout" then
                nextIndex = res.headers["x-etcd-index"] + 1
            end
        end
    end

    local ok, err = ngx_timer_at(0, watch, self, nextIndex)
    if not ok then
        log_error("Error start watch: ", err)
    end
    return
end

function _M.new(self,conf)
	return setmetatable({conf = conf},mt)
end

function _M.init(self)
   	local ok, err = ngx_timer_at(0, watch, self, nextIndex)
     	if not ok then
      		log_error("Error start watch: " .. err)
		return nil, err
     	end
     	return 1 
end

function _M.status(self)
	return json.encode(self)
end

function _M.get_hash_method(self,name)
	return self[name]
end

return _M
