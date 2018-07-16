------------------------�ű�������------------------------
--ע����Щ�ű��Ƿ��͵�Զ��Redis���ݿ���ȥִ�е�

local _M = {} -- �ֲ��ı���
_M._VERSION = '1.0' -- ģ��汾

-----------------------------------------------------------------------
----------------------[[У���˻���Ч�ԵĽű�]]---------------------------
--EVAL script numkeys key [key ...] arg [arg ...]
--���� numkeys=1 KEYS[1]=UserName ARGV[1]=SecretKey
--���� true|false
--ʾ����
--EVAL script_check_username 1 11111111 aaaaaaaa
_M.script_check_username = [[
	local key="<AUTHUSER>_"..KEYS[1]
	local secretkey=redis.pcall('hget',key,"SecretKey")
	if not secretkey then
		return {["err"]="secretkey is empty"}
	elseif secretkey~=ARGV[1] then
		return {["err"]="secretkey dismatch"}
	else
		return {["ok"]="secretkey match success"}
	end
]]

-----------------------------------------------------------------------
----------------------[[У�����Ȩ�޵Ľű�]]---------------------------
--EVAL script numkeys key [key ...] arg [arg ...]
--���� numkeys=1 KEYS[1]=serialnumber ARGV[1]=authcode ARGV[2]=attribute
--���� true|false
--ʾ����
--EVAL script_check_authcode 1 11111111 aaaaaaaa read
_M.script_check_authcode = [[
	local key="<AUTHCODE>_"..KEYS[1]
	local authcode=redis.pcall('hget',key,ARGV[2])
	if not authcode then
		return {["err"]="authcode is empty"}
	elseif authcode~=ARGV[1] then
		return {["err"]="authcode dismatch"}
	else
		return {["ok"]="authcode match success"}
	end
]]

return _M
