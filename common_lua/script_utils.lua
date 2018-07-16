------------------------脚本工具箱------------------------
--注意这些脚本是发送到远端Redis数据库中去执行的

local _M = {} -- 局部的变量
_M._VERSION = '1.0' -- 模块版本

-----------------------------------------------------------------------
----------------------[[校验账户有效性的脚本]]---------------------------
--EVAL script numkeys key [key ...] arg [arg ...]
--参数 numkeys=1 KEYS[1]=UserName ARGV[1]=SecretKey
--返回 true|false
--示例：
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
----------------------[[校验操作权限的脚本]]---------------------------
--EVAL script numkeys key [key ...] arg [arg ...]
--参数 numkeys=1 KEYS[1]=serialnumber ARGV[1]=authcode ARGV[2]=attribute
--返回 true|false
--示例：
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
