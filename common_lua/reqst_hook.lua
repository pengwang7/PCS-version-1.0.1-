-- zheng-ji
-- 
local reqmonit = require("common_lua.reqmonit")
local request_time = ngx.now() - ngx.req.start_time()
reqmonit.stat(ngx.shared.statics_dict, "reqstatus_all_host", request_time)
if tonumber(ngx.var.status) >= 400 then
    reqmonit.stat_5xx(ngx.shared.statics_dict, "reqstatus_all_host")
end
