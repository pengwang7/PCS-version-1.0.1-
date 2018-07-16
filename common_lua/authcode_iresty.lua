----------------------�ṩЧ�ʸ��õ�authcode��У�麯��
--ʹ�ñ��ػ��������Ч��
local redis_iresty = require("common_lua.redis_iresty")

local _M = {} 		-- �ֲ��ı���
_M._VERSION = '1.0' -- ģ��汾

--------------------------------------------------------------------------
local function reflesh_authcode_from_redis(redis_ip,redis_port,uuid,attribute)
	--�����ݿ��ж�ȡauthcode
	local opt = {["redis_ip"]=redis_ip,["redis_port"]=redis_port,["timeout"]=3}
	local auth_red_handler = redis_iresty:new(opt)
	if not auth_red_handler then
		ngx.log(ngx.ERR, "redis_iresty:new red_handler failed",uuid)
		return false,"redis_iresty:new red_handler failed"
	end
	ngx.log(ngx.ERR, "uuid------>", uuid)
	ngx.log(ngx.ERR, "attribute---->", attribute)
	local authcode, err = auth_red_handler:hget("<AUTHCODE>_"..uuid,attribute)
	ngx.log(ngx.ERR, "->>>>>", authcode)
	if not authcode then
		ngx.log(ngx.ERR, "hget authcode failed",uuid)
		return false,"hget authcode failed"
	end

	--����authcode��ˢ�µ�ʱ��
	local key_authcode_attr = string.format("%d:%s:%s",redis_port,uuid,attribute)
	local key_freshtime = string.format("reflesh_time:%d:%s",redis_port,uuid)
	ngx.shared.shared_data:set(key_authcode_attr, authcode)
	ngx.shared.shared_data:set(key_freshtime, os.time())
	return authcode
end

function _M.simple_check_authcode(redis_ip,redis_port,uuid,attribute,authcode)

	local key_authcode_attr = string.format("%d:%s:%s",redis_port,uuid,attribute)
	local key_freshtime = string.format("reflesh_time:%d:%s",redis_port,uuid)

	local last_authcode = ngx.shared.shared_data:get(key_authcode_attr)
	local last_freshtime = ngx.shared.shared_data:get(key_freshtime)
	if not last_authcode then
		last_authcode="null"
		last_freshtime = 0;
	end
	if not last_freshtime then
		last_freshtime = 0;
	end
	local diff = os.time()-last_freshtime
	ngx.log(ngx.ERR, "last_authcode: ", last_authcode)
	ngx.log(ngx.ERR, "authcode: ", authcode)
	if last_authcode ~= authcode then
		if (diff>=180) or (diff<0) then	--3����
			ngx.log(ngx.ERR, "NNNN")
			ngx.log(ngx.ERR, "redis_ip--->", redis_ip)
			ngx.log(ngx.ERR, "redis_port--->", redis_port)
			local cur_authcode,err = reflesh_authcode_from_redis(redis_ip,redis_port,uuid,attribute)
			ngx.log(ngx.ERR, "cur_authcode: ", cur_authcode)
			if cur_authcode == authcode then
				return true
			end
		end
		return false,"invalid authcode "
	else
		if (diff>=1800) or (diff<0) then	--30����
			ngx.log(ngx.ERR, "MMMM")
			local cur_authcode,err = reflesh_authcode_from_redis(redis_ip,redis_port,uuid,attribute)
			ngx.log(ngx.ERR, "cur_authcode: ", cur_authcode)
			if cur_authcode ~= authcode then
				return false,"invalid authcode "
			end
		end
		return true
	end
end


--uuid 		�豸uuid
--attribute	��Ȩ������
--devtime	�豸��ʱ��
--custom	�Զ����ַ���
--signature	ǩ��ֵ
function _M.advanced_check_authcode(redis_ip,redis_port,uuid,attribute,dev_time,dev_custom,dev_signature)

	--���ʱ���Ƿ����
    if math.abs(ngx.time()-devtime) > 15*60 then
        return false,"invalid devtime"
    end

	--���ǩ���Ƿ����
	local key_authcode_attr = string.format("%d:%s:%s",redis_port,uuid,attribute)
	local key_freshtime = string.format("reflesh_time:%d:%s",redis_port,uuid)
	local last_authcode = ngx.shared.shared_data:get(key_authcode_attr)
	local last_freshtime = ngx.shared.shared_data:get(key_freshtime)
	if not last_authcode then
		last_authcode = "***";	--������������©����
	end
	if not last_freshtime then
		last_freshtime = 0;
	end
	local diff = os.time()-last_freshtime

    local authorization = ngx.encode_base64(ngx.hmac_sha1(last_authcode, dev_custom))
	if authorization ~= dev_signature then
		if (diff>=180) or (diff<0) then	--3����
			local cur_authcode,err = reflesh_authcode_from_redis(redis_ip,redis_port,uuid,attribute)
			authorization = ngx.encode_base64(ngx.hmac_sha1(cur_authcode, dev_custom))
			if authorization == dev_signature then
				return true
			end
		end
		return false,"invalid authcode"
	else
		if (diff>=1800) or (diff<0)  then	--30����
			local cur_authcode,err = reflesh_authcode_from_redis(redis_ip,redis_port,uuid,attribute)
			authorization = ngx.encode_base64(ngx.hmac_sha1(cur_authcode, dev_custom))
			if authorization ~= dev_signature then
				return false,"invalid authcode"
			end
		end
		return true
	end
end

return _M
