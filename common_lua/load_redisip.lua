--�����ݿ�IP��ַ�Ļ�ȡ��������ͳһ��
--��ǰ������ݿ��IP��ַ������д�뵽�����ڴ���ȥ��
--������ ->��������->�������͵����̽���
local myconfig = require("config_lua.myconfig")			--������
local wanip_iresty = require("common_lua.wanip_iresty")


local function load_param_from_env()
	--��ȡ���������е���Ϣ(������DaoCloud������)
	local ServerArea = os.getenv("ServerArea")
	if not ServerArea then
		ServerArea = "Asia:China:Beijing"
	end
	local VendorName = os.getenv("VendorName")
	if not VendorName then
		VendorName = "General"
	end
	ngx.shared.shared_data:set("Heartbeat_ServerArea", ServerArea)
	ngx.shared.shared_data:set("Heartbeat_VendorName", VendorName)	
	return true
end

--�������е�Redis IP��ַ��Ϣ
local function load_redis_ip_from_env()
	local redis_center = os.getenv("RedisCenter")
	if redis_center then
		ngx.shared.shared_data:set("myconfig_dss_redis4user_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_pms_redis4user_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_css_redis4user_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_tps_redis4user_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_p2p_redis4user_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_rps_redis4user_ip",redis_center)
		ngx.shared.shared_data:set("myconfig_dss_redis4auth_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_pms_redis4auth_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_css_redis4auth_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_tps_redis4auth_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_p2p_redis4auth_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_rps_redis4auth_ip",redis_center)
		ngx.shared.shared_data:set("myconfig_dss_redis4status_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_tps_redis4status_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_p2p_redis4status_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_alc_redis4status_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_css_redis4status_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_rps_redis4status_ip",redis_center)
		ngx.shared.shared_data:set("myconfig_wps_redis4status_ip",redis_center)	
		ngx.shared.shared_data:set("myconfig_upg_redis4status_ip",redis_center)		
		ngx.shared.shared_data:set("myconfig_pms_redis4work_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_dss_pic_redis4namemap_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_pms_pic_redis4namemap_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_css_streaminfo_redis4namemap_ip", redis_center)
		ngx.shared.shared_data:set("myconfig_redis4cfg_ip", redis_center)
		ngx.log(ngx.NOTICE,"load_all_redis_ip from env")
	end
	return true
end

local function load_fdfs_ip_from_env()
	local fdfs_ip = os.getenv("FastDFSTracker")
	if fdfs_ip then
		ngx.shared.shared_data:set("myconfig_pic_fdfs_tracker_ip", fdfs_ip)
	end
	return true
end
load_param_from_env()
load_redis_ip_from_env()
load_fdfs_ip_from_env()
