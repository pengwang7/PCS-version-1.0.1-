-- 功能：从cpath的各个路径中查找共享库文件(so_name)，返回共享库的绝对路径
-- 参数：cpath (类型string) 查找路径，各路径之间以分号分隔
--       so_name (类型string) 需查找的共享库文件名
-- 返回值：如果找到，则返回共享文件的绝对路径，如果没找到，则返回nil
local function find_shared_obj(cpath, so_name)
    local string_gmatch = string.gmatch
    local string_match = string.match

    for k, v in string_gmatch(cpath, "[^;]+") do
        local so_path = string_match(k, "(.*/)")
        so_path = so_path .. so_name

        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io.open(so_path)
        if f ~= nil then
            io.close(f)
            return so_path
        end
    end
end


local _M = {} -- 局部的变量
_M._VERSION = '1.0' -- 模块版本

_M.find_shared_obj = find_shared_obj

return _M
