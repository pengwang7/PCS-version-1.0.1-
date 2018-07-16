#!/usr/local/openresty/luajit/bin/luajit

local p = "/xm_workspace/xmcloud3.0/OpenrestyPullCertsServer/common_lua/"
local m_package_path = package.path
package.path = string.format( "%s;%s?.lua;%s?/init.lua", m_package_path, p, p )
