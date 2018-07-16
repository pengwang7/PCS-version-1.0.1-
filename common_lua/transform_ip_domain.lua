
local resolver = require("resty.dns.resolver")
local http_iresty = require("resty.http")

--域名解析的过程：查找本地所对应的dns服务器的地址==》连接到dns服务器==》dns服务器返回一个结果集==》在结果集中查找域名所对应的ip地址==》将ip地址返回
--一个域名可能对应多个ip地址但一个ip只能对应一个域名 多个ip可以对应一个或多个域名
local _M = {}

local function get_ip_by_dns(domain, dns_server_ip)

	--设置连接参数 连接dns服务器
	local res, err = resolver:new {
		nameservers = {dns, {dns, 53}},
		retrans = 3,		--如果超时的话重新连接的次数
		timeout = 5000,   	--5 seconds             
	}
	
	if not res then
		return false, "dns resolv failed" .. err
	end
	
	--查询域名所对应的ip地址 返回的应该为一个结果集 因为一个域名可能对应多个ip地址
	local chunk, err = res:query(domain)
	
	if not chunk then
		return false, "dns query failed" .. err
	end
	
	--找到域名对应的某个ip地址之后就返回
	for i, ans in ipairs(chunk) do
		if ans.address then
			return ans.address
		end
	end

	return false, "get_ip_by_dns failed"
end

local function get_system_dns()
	
	local dns1_server_ip = nil
	local dns2_server_ip = nil
	
	--linux系统中的etc/resolv.conf获取dns服务器地址 
	local file = io.open("etc/resolv.conf", "r")
	
	--将dns服务器的地址分别读到dns1_server_ip&&dns2_server_ip中
	if file then
		for line in file():lines do
			if not dns1_server_ip then
				dns1_server_ip = string.match(line, "nameserver (%d+.%d+.%d+.%d+)")
			else if not dns2_server_ip then
				dns2_server_ip = string.match(line, "nameserver (%d+.%d+.%d+.%d+)")
			else
				break;
			end
		end
	end
	
	--关闭打开的文件
	file:close()
	
	return dns1_server_ip, dns2_server_ip
end

local function get_domain_ip(domain)

	--多个dns服务器地址防止出现在一个dns服务器上解析失败
	local dns1_server_ip, dns2_server_ip = get_system_dns()
	
	if dns1_server_ip then
		local ip, err = get_ip_by_dns(domain, dns1_server_ip) 
		if ip then
			return ip
		end
	end
	
	if dns2_server_ip then
		local ip, err = get_ip_by_dns(domain, dns2_server_ip)
		if ip then
			return ip
		end
	end
	
	--本机的dns服务器的地址如果都不可用的话使用“8.8.8.8”
	local ip, err = get_ip_by_dns(domain, "8.8.8.8")
	if ip then
		return ip
	end
	
	ngx.log(ngx.ERR, "get_ip_by_dns failed")
	return false, "get_ip_by_dns failed"
end

local function getfrom_sohu()

	--得到pv.sohu.com对应的ip地址
	local ipaddr, err = get_domain_ip("pv.sohu.com")
	if not ipaddr then
		ngx.log(ngx.ERR, "get_domain_ip failed")
		return false, "get_domain_ip by pv.sohu.com failed"
	end
	
	--连接到对应的网页返回数据returnCitySN = {"cip": "60.12.9.26", "cid": "330100", "cname": "浙江省杭州市"};"
	local httpc = http_iresty:new()
	httpc:set_timeout(3000)
	httpc:connect(ipaddr, 80)
	local req, err = httpc:request {
		path = "/cityjson",
		headers = {
			["Host"] = "pv.sohu.com"
		},
	}
	
	if not req then
		ngx.log(ngx.ERR, "request from pv.sohu.com failed")
		return false, "request failed"
	end
	
	--读取返回的数据
	local reader = req.body_reader
	local chunk, err = reader(8192)
	if (not chunk) or err then
		ngx.log(ngx.ERR, "reader failed")
		return false, "reader failed"
	end
	
	--拿到数据中的ip地址
	local ipres = string.match(chunk, "{\"cip\": \"(%d+.%d+.%d+.%d+)\"")
	if ipres then
		return ipres
	end
	
	ngx.log(ngx.ERR, "invalid ip address")
	return false, "invalid ip addr"	
end


--域名解析
local function _M.getdomainip(domain)
	
	if domain then
		return get_domain_ip(domain)
	else
		ngx.log(ngx.ERR, "the domain is empty")
		return false, "the domain is empty"
	end
	
	return false
end

local function _M.getpubnetip()

	--搜狐提供了获取自己ip地址的功能
	local ipaddr, err = getfrom_sohu()
	if ipaddr then
		local res1 = string.match(ipaddr, "(10.%d+.%d+.%d+)")
		local res2 = string.match(ipaddr, "(172.%d+.%d+.%d+)")
		local res3 = string.match(ipaddr, "(192.168.%d+.%d+)")
		local res4 = string.match(ipaddr, "(%d+.%d+.%d+.%d+)")
	--检查获取的地址是否为外网地址
		if res1 == nil and res2 == nul and res3 == nil and res4 ~= nil then
			return ipaddr
		else
	end
	
	ngx.log(ngx.ERR, "get ip address from souhu failed")

	return false, "get ip address failed"
end

return _M