local _M = {} -- 局部的变量
_M._VERSION = '1.0' -- 模块版本


-----------------table的相关的一些常用函数-----------------
function _M.table_is_empty(t)
    return next(t) == nil
end

function _M.table_is_array(t)
  if type(t) ~= "table" then return false end
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

function _M.table_is_map(t)
  if type(t) ~= "table" then return false end
  for k,_ in pairs(t) do
    if type(k) == "number" then  return false end
  end
  return true
end

-----------------table的调试打印-----------------
local function MultiString(s,n)
    local r=""
    for i=1,n do
      r=r..s
    end
    return r
end
--o ,obj;b use [];n \n;t num \t;
local function TableToString(o,n,b,t)
    if type(b) ~= "boolean" and b ~= nil then
        print("expected third argument %s is a boolean", tostring(b))
    end
    if(b==nil) then
		b=true
	end
    t=t or 1
    local s=""
    if type(o) == "number" or
        type(o) == "function" or
        type(o) == "boolean" or
        type(o) == "nil" then
        s = s..tostring(o)
    elseif type(o) == "string" then
        s = s..string.format("%q",o)
    elseif type(o) == "table" then
        s = s.."{"
        if(n)then
            s = s.."\n"..MultiString("  ",t)
        end
        for k,v in pairs(o) do
            if b then
                s = s.."["
            end

            s = s .. TableToString(k,n, b,t+1)

            if b then
                s = s .."]"
            end

            s = s.. " = "
            s = s.. TableToString(v,n, b,t+1)
            s = s .. ","
            if(n)then
                s=s.."\n"..MultiString("  ",t)
            end
        end
        s = s.."}"
    end
    return s;
end
function _M.printTable(o)
	local s = TableToString(o,1,true,1)
	print(s)
end

return _M
