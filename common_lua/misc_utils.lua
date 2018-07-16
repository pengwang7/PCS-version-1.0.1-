-- ���ܣ���cpath�ĸ���·���в��ҹ�����ļ�(so_name)�����ع����ľ���·��
-- ������cpath (����string) ����·������·��֮���Էֺŷָ�
--       so_name (����string) ����ҵĹ�����ļ���
-- ����ֵ������ҵ����򷵻ع����ļ��ľ���·�������û�ҵ����򷵻�nil
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


local _M = {} -- �ֲ��ı���
_M._VERSION = '1.0' -- ģ��汾

_M.find_shared_obj = find_shared_obj

return _M
