#!/usr/local/openresty/luajit/bin/luajit-2.1.0-alpha

--[�趨����·��]
--���Զ����·������package������·���С�Ҳ���Լӵ���������LUA_PATH��
--local p = "/root/alarm_test/XmCloudAlarm/OpenRestyAlarmServer/"
--local p = "/home/wangpeng/ngx/openresty/common_lua/"
local p = "/root/wangpeng/common_lua/"
local m_package_path = package.path
package.path = string.format("%s;%s?.lua;%s?/init.lua",m_package_path, p, p)
