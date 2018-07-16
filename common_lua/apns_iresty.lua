-- file name: resty/apns_iresty.lua
--apns_iresty�ӿڵķ�װ
local cjson = require("cjson.safe")

--_M ���Ϊһ��table,Ԥ����_M �ĳ�����Ϣ
local _M = {}
_M._VERSION = '0.01'


local mt = { __index = _M }

--��Ϣ��ʽΪ[{apptoken:%s,uuid:%s,msgbody:%s}]
--2016.8.15����һ��voice�ֶ�
function _M.sendmsg(self,apptoken,uuid,channel,level,voice,alarmid,subsn,alarmbody,evType)
	--print("sendmsg----------------->apptoken=",apptoken)
	local sock = ngx.socket.udp()
	if not sock then
		ngx.log(ngx.ERR, "new ngx.socket.udp  failed")
		return false, "new ngx.socket.udp failed"
	end
	local ok, err = sock:setpeername(self.unixsock_path)
	if not ok then
		ngx.log(ngx.ERR,"failed to connect to the datagram unix domain socket:"..self.unixsock_path, err)
		return false, "failed to connect to the datagram unix domain socket:"..self.unixsock_path
	end
	--print("succ to connect to the datagram unix domain socket: ", err)
	--����һ����Ϣ��ʽ
	local msgtable = {};
	msgtable["apptoken"] = apptoken
	msgtable["uuid"] = uuid
	msgtable["channel"] = channel
	msgtable["level"] = level
	msgtable["alarmid"] = alarmid
	msgtable["voice"] = voice
	msgtable["event"] = evType
	if subsn ~= nil then
		msgtable["subsn"] = subsn
	end
	msgtable["msgbody"] = alarmbody
	local senddata = cjson.encode(msgtable)
	local ok, err = sock:send(senddata)
	if not ok then
		ngx.log(ngx.ERR,"failed to send data to the datagram unix domain socket:"..self.unixsock_path, err)
		return false, "failed to send data to the datagram unix domain socket:"..self.unixsock_path
	end
	sock:settimeout(3000)  -- one second timeout
	local recvdata, err = sock:receive(128)
	if not recvdata then
		ngx.log(ngx.ERR,"read resp timeout")
		return false,"read resp from datagram unix domain socket timeout"
	end
	ngx.log(ngx.NOTICE,"receive resp ...",recvdata)
	return true,recvdata
end

function _M.new(self, opts)
    --�趨���ӳ�ʱʱ���ѡ��
    opts = opts or {}
    local timeout = (opts.timeout and opts.timeout * 3000) or 3000
	local unixsock_path = nil;
	_,end_pos,line = string.find(opts.apptype,"%w+:([^:]*)",0)
	if line ~= nil then
		unixsock_path = "unix:/tmp/apns_unixsocket_"..line
    else
		ngx.log(ngx.ERR, "invalid apptype",opts.apptype)
		return nil
	end
    return setmetatable({
            timeout = timeout,
			unixsock_path = unixsock_path}, mt)
end

return _M
