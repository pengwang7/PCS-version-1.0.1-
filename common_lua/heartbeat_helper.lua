--每一个功能服务器都需要将自己的信息定期的发送到redis中去，这样便于集群管理。
local myconfig = require("config_lua.myconfig")				--配置项
local wanip_iresty = require("common_lua.wanip_iresty")
local redis_iresty = require("common_lua.redis_iresty")
local reqmonit = require("common_lua.reqmonit")
	
local redis_ip="127.0.0.1"
local redis_port=6437

local function load_cfg_ip_addr()
	redis_port = myconfig.myconfig_redis4cfg_port
	redis_ip = ngx.shared.shared_data:get("myconfig_redis4cfg_ip")
	if not redis_ip then
		local ip,err = wanip_iresty.getdomainip(myconfig.myconfig_redis4cfg_ip)
		if not ip then
			ngx.log(ngx.ERR,"getdomainip failed ",err,myconfig.myconfig_redis4cfg_ip)
			return false
		end
		ngx.shared.shared_data:set("myconfig_redis4cfg_ip", ip)
		redis_ip = ip
	end
	return true
end

local function init_heartbeat()

	--控制此函数只执行一次
	local ServerIP = ngx.shared.shared_data:get("Heartbeat_ServerIP")
	if ServerIP then
		return true
	end

	----------------------------------------------------
	--获取服务器自身的IP
	local ServerIP,err = wanip_iresty.getwanip()
	if not ServerIP then
		ngx.log(ngx.ERR,"getwanip failed ",err)
		return false
	end

	--读取ngx.全局变量(在nginx.conf中设定的)
	local ServerType = ngx.shared.shared_data:get("ServerType");
	if not ServerType then
		ServerType = "Default"
	end
	local ServerPort = ngx.shared.shared_data:get("ServerPort");
	if not ServerPort then
		ServerPort = 0
	end

	--将基本信息写入到共享内存中
	ngx.shared.shared_data:set("Heartbeat_ServerType", ServerType)
	ngx.shared.shared_data:set("Heartbeat_ServerIP", ServerIP)
	ngx.shared.shared_data:set("Heartbeat_ServerPort", ServerPort)
	--ngx.shared.shared_data:set("Heartbeat_ServerArea", ServerArea)	在load_redisip中初始化，原因:worlker中取不到环境变量
	--ngx.shared.shared_data:set("Heartbeat_VendorName", VendorName)	
	ngx.shared.shared_data:set("Heartbeat_StartTime",os.time());
	ngx.shared.shared_data:set("Heartbeat_Status", 0)
	ngx.shared.shared_data:set("Heartbeat_ActiveIndex", 0)
	ngx.shared.shared_data:set("Heartbeat_RetOK", 0)
	ngx.shared.shared_data:set("Heartbeat_RetError", 0)
	return true
end

local function do_heartbeat()

	--进行统计
	local count, avg, total_time, server_err_num = reqmonit.analyse(ngx.shared.statics_dict, "reqstatus_all_host")
	ngx.shared.shared_data:set("Heartbeat_Status", count)		--这一个统计间隔内的总的http请求数
	ngx.shared.shared_data:set("Heartbeat_ActiveIndex", avg)	--每一个命令的处理时间
	ngx.shared.shared_data:set("Heartbeat_RetOK", count-server_err_num)
	ngx.shared.shared_data:set("Heartbeat_RetError", server_err_num)	
	
	--将信息更新到数据库中去
	local opt = {["redis_ip"]=redis_ip,["redis_port"]=redis_port,["timeout"]=3}
	local red_handler = redis_iresty:new(opt)
	if not red_handler then
		ngx.log(ngx.ERR, "redis_iresty:new red_handler failed")
		return false,"redis_iresty:new red_handler failed"
	end

	local ServerType = ngx.shared.shared_data:get("Heartbeat_ServerType");
	local ServerIP = ngx.shared.shared_data:get("Heartbeat_ServerIP");
	local ServerPort = ngx.shared.shared_data:get("Heartbeat_ServerPort");
	local ServerArea = ngx.shared.shared_data:get("Heartbeat_ServerArea");
	local VendorName = ngx.shared.shared_data:get("Heartbeat_VendorName");
	local StartTime = ngx.shared.shared_data:get("Heartbeat_StartTime");
	local Status = ngx.shared.shared_data:get("Heartbeat_Status");
	local ActiveIndex = ngx.shared.shared_data:get("Heartbeat_ActiveIndex");
	local RetOK = ngx.shared.shared_data:get("Heartbeat_RetOK");
	local RetError = ngx.shared.shared_data:get("Heartbeat_RetError");
	local RunSeconds = os.time()-StartTime
	if(not Status) or (Status == 0) then
		Status = ActiveIndex
	end

	local totalmap_key = ServerType.."Map"
	local ok, err = red_handler:hset(totalmap_key,ServerIP,ServerPort)
	if not ok then
		ngx.log(ngx.ERR, "write to redis failed", err)
		return false, "write to redis failed"
	end
	local ok, err = red_handler:expire(totalmap_key,180)	--TTL=3分钟
	if not ok then
		ngx.log(ngx.ERR,":expire totalmap_key failed ",totalmap_key,err)
		return false
	end

	local server_key = ServerType.."_"..ServerIP
	local ok, err = red_handler:hmset(server_key,
								"ServerIP",ServerIP,
								"ServerPort",ServerPort,
								"ServerArea",ServerArea,
								"VendorName",VendorName,
								"RunSeconds",RunSeconds,
								"Status",Status,
								"ActiveIndex",ActiveIndex,
								"RetOK",RetOK,
								"RetError",RetError)
	if not ok then
		ngx.log(ngx.ERR,":hmset server info to redis failed ",ServerIP,err)
		return false
	end
	local ok, err = red_handler:expire(server_key,180)		--TTL=3分钟
	if not ok then
		ngx.log(ngx.ERR,":expire server_key failed ",server_key,err)
		return false
	end

	return true
end

--[定时器]
local heartbeat_interval = 60
local handler = nil
handler = function ()

	--加载基本的ip地址信息
	local ok = load_cfg_ip_addr()
	if not ok then
		ngx.log(ngx.ERR,"load_cfg_ip_addr failed ")
	else
		init_heartbeat()	--此函数内部控制只执行一次
		do_heartbeat()
	end

	--重启定时器
	print("----------------------restart heartbeat timer--------------------------->")
	local ok, err = ngx.timer.at(heartbeat_interval, handler)
	if not ok then
		ngx.log(ngx.ERR, "failed to startup heartbeat timer...", err)
	end
	return true
end

--启动一个定时器用来刷新数据库
local ok = ngx.shared.shared_data:add("is_init_flag",1)--如果已经键值存在就会返回nil
if ok then
	--启动一个定时器用来刷新数据库
	local ok, err = ngx.timer.at(heartbeat_interval, handler)
	if not ok then
		ngx.log(ngx.ERR, "failed to startup heartbeat timer...", err)
	end
	print("start heartbeat helper ...")
end

