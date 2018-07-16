-- file name: resty/alc_iresty.lua
--alc_iresty�ӿڵķ�װ
--������android�ͻ��˷������ݵĽӿڷ�װ

local tableutils = require("common_lua.tableutils")		--��ӡ����
local http_iresty = require ("resty.http")
local redis_iresty = require("common_lua.redis_iresty")
local cjson = require("cjson.safe")

local _M = {} -- �ֲ��ı���
_M._VERSION = '1.0' -- ģ��汾
local mt = { __index = _M }

--��android�ͻ����ķ�����Ϣ
function _M.sendmsg(self,apptoken,alarmbody)
	--print("sendmsg----------------->",apptoken,self.alc_redisstatus_ip,self.alc_redisstatus_port)
	--����apptoken��alc״̬���������ҵ���Ӧ�Ŀͻ������ڵķ�������ַ��Ϣ
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
	
	--��alc����������Ϣ
	local httpc = http_iresty.new()
	httpc:set_timeout(3000)
	local ok, err = httpc:connect(serverip,6603)		--����ط��̶�д����̫��������Ҫ��취
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
	if res.status == 202 then		--��������������
		ngx.log(ngx.INFO,"publish succ.")
		return true,"publish succ."
	elseif res.status == 201 then	--�����߲�����
		ngx.log(ngx.WARN,"client is offline 2")
		return false,"client is offline 2"
	else
		ngx.log(ngx.WARN,"res.status is unexpected",res.status)
		return false,"res.status is unexpected. res.status="..res.status
	end
end

function _M.new(self, opts)
	--�趨���ӳ�ʱʱ���ѡ��
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

