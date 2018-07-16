-- file name: resty/alc_iresty.lua
--alc_iresty接口的封装
--这是往android客户端发送数据的接口封装

local tableutils = require("common_lua.tableutils")		--打印工具
local http_iresty = require ("resty.http")
local redis_iresty = require("common_lua.redis_iresty")
local cjson = require("cjson.safe")

local _M = {} -- 局部的变量
_M._VERSION = '1.0' -- 模块版本
local mt = { __index = _M }

--往android客户中心发送消息
function _M.sendmsg(self,apptoken,alarmbody)
	--print("sendmsg----------------->",apptoken,self.alc_redisstatus_ip,self.alc_redisstatus_port)
	--根据apptoken从alc状态服务器中找到对应的客户端所在的服务器地址信息
	ngx.log(ngx.ERR, "_M.sendmsg for android")
	local opt = {["redis_ip"]=self.alc_redisstatus_ip,["redis_port"]=self.alc_redisstatus_port,["timeout"]=3}
	local red_handler = redis_iresty:new(opt)
	if not red_handler then
	    ngx.log(ngx.ERR, "redis_iresty:new failed")
		return false,"redis_iresty:new failed,connect to app client status redis failed"
	end
	
	local serverip, err = red_handler:hget(apptoken,"ServerIP")
	if not serverip then
		ngx.log(ngx.WARN,"hget apptoken ServerIP failed",apptoken,err)
		return false,"hget apptoken ServerIP failed:client offline"
	end
	
	--向alc发布报警消息
	local httpc = http_iresty.new()
	httpc:set_timeout(3000)
	local ok, err = httpc:connect(serverip,6603)		--这个地方固定写死不太合理，后续要想办法
	if not ok  then
		ngx.log(ngx.ERR,"httpc:connect failed",serverip,6603,err)
		return false,string.format("httpc:connect failed,serverIP=%s,port=%d",serverip,6603)
	end
	local res, err = httpc:request{
		method = "POST",
		path = "/publish?token="..apptoken,
		headers = {
			["Host"] = serverip,
		},
		body = cjson.encode(alarmbody),
	}
	ngx.log(ngx.ERR, "STATUS:", res.status)
	if res.status == 202 then		--订阅者正常接收
		ngx.log(ngx.INFO,"publish succ.")
		return true,"publish succ."
	elseif res.status == 201 then	--订阅者不在线
		ngx.log(ngx.WARN,"client is offline 2")
		return false,"client is offline 2"
	else
		ngx.log(ngx.WARN,"res.status is unexpected",res.status)
		return false,"res.status is unexpected. res.status="..res.status
	end
end

function _M.new(self, opts)
	--设定连接超时时间的选项
	opts = opts or {}
    local timeout = (opts.timeout and opts.timeout * 3000) or 3000
    local alc_redisstatus_ip = opts.alc_ip or "127.0.0.1"
    local alc_redisstatus_port = opts.alc_port or 6479
    return setmetatable({
            timeout = timeout,
			alc_redisstatus_ip = alc_redisstatus_ip,
			alc_redisstatus_port = alc_redisstatus_port}, mt)
end

return _M

