local resolver = require ("resty.dns.resolver")
local cjson = require("cjson.safe")
local http_iresty = require ("resty.http")
local _M = {}
_M._VERSION = '0.01'
local mt = { __index = _M }

function _M.get_domain_ip_by_dns(self,domain)
	local dns = "8.8.8.8"
	local r, err = resolver:new{
      		nameservers = {dns, {dns, 53} },
      		retrans = 5,  -- 5 retransmissions on receive timeout
      		timeout = 2000,  -- 2 sec
  	}
	if not r then
      		return nil, "failed to instantiate the resolver: " .. err
  	end
	local answers, err = r:query(domain)
  	if not answers then
      		return nil, "failed to query the DNS server: " .. err
  	end
  	if answers.errcode then
      		return nil, "server returned error code: " .. answers.errcode .. ": " .. answers.errstr
  	end

  	for i, ans in ipairs(answers) do
    		if ans.address then
			ngx.shared.gcm_share_data:set("google_push_ip",ans.address)
			return ans.address
    		end
  	end
  	return nil, "not founded"
end

function _M.sendmsg(self,apptoken,alarmbody,DeviceName)
	local google_ip = ngx.shared.gcm_share_data:get("google_push_ip")
	if not google_ip then
		google_ip,err = self:get_domain_ip_by_dns("fcm.googleapis.com")
		if google_ip == nil then
			ngx.log(ngx.ERR,"get domain ip by dns falied :",err)
			return false,"get domain ip by dns falied"
		end
	end
	local httpc = http_iresty.new()
	httpc:set_timeout(self.timeout)
	local ok, err = httpc:connect(google_ip,80)
	if not ok  then	
		ngx.log(ngx.ERR,"httpc:connect fcm.googleapis.com failed",err)
		return false, "httpc:connect fcm.googleapis.com failed"
	end
	local jreq = {}
	jreq["data"] = alarmbody
	if DeviceName ~= nil then
		jreq["data"]["DevName"] = DeviceName
	end
	jreq["to"] = apptoken
	local Authorization = "key="..self.secret
	local res, err = httpc:request{
			ssl_verify = false,
			method = "POST",
			path = "/fcm/send",
			headers = {
					["Host"] = "fcm.googleapis.com",
					["Authorization"] = Authorization,
					["Content-Type"] = "application/json",
			    },
			body = cjson.encode(jreq),
		}
	if res == nil then
		return false, "send request failed"
	end	
	if res.status == 200 then           
		ngx.log(ngx.INFO,"publish succ...")
		local res_body, err = res:read_body()
		if res_body then
			local json_body,err = cjson.decode(res_body)
			if not json_body then
				ngx.log(ngx.ERR, "res_body_param:res body is not a json",res_body)
				return false, "req body is not a json"
			end
			local failure = json_body["failure"]
			local canonical_ids = json_body["canonical_ids"]
			if failure ~= 0 then
				local res_err = json_body["results"][1]["error"]
				if res_err and res_err == "NotRegistered" or res_err == "InvalidRegistration" then
					return false,"InvalidRegistration"
				end
			end
			if canonical_ids ~= 0 then
				local registration_id = json_body["results"][1]["registration_id"]
				if registration_id then
					return true,registration_id
				end
			end
		end
	elseif res.status == 401 then  
		ngx.log(ngx.ERR,"secret is invalid",secret)
		return false,"secret is invalid"
	elseif res.status == 411 then
		ngx.log(ngx.ERR,"secret has invalid params",secret)
		return false,"secret has invalid params"
	else
		ngx.log(ngx.WARN,"res.status is unexpected",res.status)
		return false,"res.status is unexpected. res.status="..res.status
	end
	return true
end

function _M.new(self,opts)
	opts = opts or {}
	local timeout = (opts.timeout and opts.timeout * 3000) or 3000

	local secret = nil	
	local _,end_pos,app_type = string.find(opts.apptype,"%w+:([^:]*)",0)
	if not app_type then
		return nil
	else
		local key = "GCM_"..app_type
		ngx.log(ngx.ERR,"key: ",key)
		secret = ngx.shared.gcm_share_data:get(key)
		if not secret then
			local so_path = "/xm_workspace/xmcloud3.0/gcm_certs/"..app_type
			local f = io.open(so_path,"r")
			if f ~= nil then
				secret = f:read()
				f:close()
				ngx.log(ngx.ERR,"secret key:",secret)
				ngx.shared.gcm_share_data:set(key,secret)
			else
				ngx.log(ngx.ERR,"Get secret key failed,app_type = ",app_type)
				return nil;
			end
		end
	end
	return setmetatable({timeout = timeout,secret = secret}, mt) 
end

return _M
