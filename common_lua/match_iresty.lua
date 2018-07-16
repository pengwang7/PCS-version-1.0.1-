-- file name: resty/match_iresty.lua
--match_iresty接口的封装
--这是往本地负载均衡模块发送IP地址请求的接口封装

local http_iresty = require ("resty.http")
local cjson = require("cjson.safe")

local _M = {} 		-- 局部的变量
_M._VERSION = '1.0' -- 模块版本

--向负载均衡模块发送请求,获取对应的信息（返回功能服务器的地址和数据库的地址）
function _M.get_match_server_and_redis(redis_in,service,oemid,area)
	--构造消息体
	local req_body = {["service"]=service,["oem"]=oemid,["area"]=area}
	if(redis_in ~= nil) then
		req_body["in_redis"] = redis_in
	end
	--发送消息
	local serverIP = "127.0.0.1"	--这个地方固定写死不太合理，后续要想办法
	local serverPort = 7999			
	local httpc = http_iresty.new()
	httpc:set_timeout(3000)
	local ok, err = httpc:connect(serverIP,serverPort)
	if not ok  then
		ngx.log(ngx.ERR,"httpc:connect failed ",serverIP,serverPort,err)
		return false,string.format("httpc:connect failed,serverIP=%s,port=%d",serverIP,serverPort)
	end
	local res, err = httpc:request{
		method = "POST",
		path = "/",
		headers = {
			["Host"] = serverIP,
		},
		body = cjson.encode(req_body),
	}
	if res.status == 200 then
		local  rsp_body_str,err = res:read_body()
		if not rsp_body_str then
			ngx.log(ngx.ERR, "read_body failed", err)
			return false, "read_body failed"
		end
		local res_body, err = cjson.decode(rsp_body_str)
		if not res_body or (not res_body["matched_redis"]) or (not res_body["matched_server"]) then
			ngx.log(ngx.ERR, "rsp body is not a valid json", rsp_body_str)
			return false, "rsp body is not a valid json"
		end
		
		local ok, err = httpc:set_keepalive()	--保持长连接
		if not ok then
			ngx.log(ngx.ERR,"failed to set keepalive: ", err)
		end
		return true,res_body["matched_redis"],res_body["matched_server"]
	else
		ngx.log(ngx.ERR,"get_match_server_and_redis failed,res.status=",res.status)
		return false,"get_match_server_and_redis failed,res.status="..res.status
	end
end

return _M

