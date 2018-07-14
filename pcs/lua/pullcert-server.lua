local cjson = require( "cjson.safe" )
local http_iresty = require ( "resty.http" )
local redis_iresty = require( "redis_iresty" )
--global var
local delay = 15
local limit = 1000
local timer_handler = nil
local redis_ip = "123.59.27.192"
local redis_port = "7379"
local filename_cer = "cccc.cer"
local filename_p12 = "pppp.p12"
local pem_file_directory = "/home/wangpeng/ngx/openresty/pcs/cert/"
local utc_time = 1531188480
local function pull_certificate()
--	ngx.update_time()
--	local utc_time = ngx.time()
--	if not utc_time then
--		return nil, "Get nginx utc time met error", nil
--	end
--	utc_time = utc_time + 3

	local body_str = "startTime=" .. utc_time .. "&page=1&rows=1"
	ngx.log( ngx.ERR, "string body=", body_str )

        local httpc = http_iresty:new()
	local timeout = 6000
        httpc:set_timeout( timeout )
	local url = "http://open.xmeye.net/cloudplatform/certificate/allList.do"
	local header = {}
	header["Content-Type"] = "application/x-www-form-urlencoded"
	header["Host"] = "open.xmeye.net"

	local ret, err = httpc:request_uri( url, {
			method = "POST",
			headers = header,
			body = body_str
			
	})

	if not ret then
		ngx.log( ngx.ERR, "Http request met error: ", err )
		return nil, err, nil
	else
		if ret.status == 200 then
			if ret.body == nil then
				ngx.log( ngx.ERR, "ccccccccccccccccccccccccccc" )
				return
			end
			local tabret = cjson.decode( ret.body )
			local result_code = tabret["code"]
			if result_code == 2000 then
				
				return true, nil, tabret["data"]
			else
				return nil, result_code, nil
			end
		else
			ngx.log( ngx.ERR, "Status code=", ret.status )
			return nil, ret.body, nil
		end

	end
   
	return false, nil, nil
end

local function download_certs( id, source )

	local cmd = 'curl -X GET ' .. source .. ' > ./temp_cert/temp.zip'
	local ok = os.execute( cmd )
	if not ok then
		return nil, "Download certificates failed"
	end

--[[
--	local cmd = 'wget -P ./temp_cert ' .. source
	local ok = io.popen( cmd )
	if not ok then
		return nil, "Download certificates failed"
	end
]]--	
	local fd = io.open( "./temp_cert/temp.zip" )
	if not fd then
                return nil, "Download zip file is empty"
        end

	local length = fd:seek( "end" )
	if length < limit - 500  then
		ngx.log( ngx.ERR, "zip file is empty" )
		os.execute( "rm -rf ./temp_cert/*" )
		return nil, "Download the zip is empty"
	end

	local ok = os.execute( "unzip ./temp_cert/temp.zip -d ./temp_cert/" )
	if not ok then
		ngx.log( ngx.ERR, "unzip failed" )
		return nil
	end

	local ok = os.execute( "mv ./temp_cert/*.cer ./temp_cert/cccc.cer" )
	if not ok then
		ngx.log( ngx.ERR, "fix cer name failed" )
		return nil
	end

	local ok = os.execute( "mv ./temp_cert/*.p12 ./temp_cert/pppp.p12" )
	if not ok then
		ngx.log( ngx.ERR, "fix p12 name failed" )
		return nil
	end

--	local ok = os.execute( exec_cmd )
--	if not ok then
--		ngx.log( ngx.ERR, "Rename met error" )
--		return nil
--	end

	fd:close()
	os.execute( "rm -rf ./temp_cert/*.zip" )

	return true
end

local function send_file_status( succ, id, msg )
	if not id or not msg then
		return nil, "invalid args for send_file_status"
	end

	local iid = id
	local mmsg = msg
	local ttype = nil

	if succ == 1 then
		ttype = "true"
	else
		ttype = "false"
	end

	local body_str = "id=" .. iid .. "&type=" .. ttype .. "&errorMsg=" .. mmsg	

        local httpc = http_iresty:new()
        local timeout = 6000
        httpc:set_timeout( timeout )
        local url = "http://open.xmeye.net/cloudplatform/certificate/setTypeById.do"
        local header = {}
        header["Content-Type"] = "application/x-www-form-urlencoded"
        header["Host"] = "open.xmeye.net"

        local ret, err = httpc:request_uri( url, {
                        method = "POST",
                        headers = header,
                        body = body_str

        })

	
	if not ret then
                ngx.log( ngx.ERR, "send_file_status Http request met error: ", err )
                return nil, err
        else
                if ret.status == 200 then
                        local tabret = cjson.decode( ret.body )
                        local result_code = tabret["code"]
			ngx.log( ngx.ERR, "result_code=", result_code )
                        if result_code == 2000 then
				ngx.log( ngx.ERR, "send_file_status succ ... " )
                                return true, nil
                        else
				ngx.log( ngx.ERR, "send_file_status error code=", result_code )
                                return nil, result_code
                        end
                else
                        ngx.log( ngx.ERR, "send_file_status Status code=", ret.status )
                        return nil, ret.status
                end
        end
	
	return nil, nil
end

local function transform_file( bundleid, id )
	local cerfilepem = "Cer" .. bundleid .. ".pem"
	local keyfilepem = "Key" .. bundleid .. ".pem"
	--Dynamically generate shell scripts
	os.execute( "echo '#!/bin/bash' >> ./lua/cmd1.sh" )
	os.execute( "echo '#!/bin/bash' >> ./lua/cmd2.sh" )
	os.execute( "echo '#!/bin/bash' >> ./lua/cmd3.sh" )
	
	local cmd1 = 'openssl x509 -in ./temp_cert/' .. filename_cer .. ' -inform der -out ./temp_cert/' .. cerfilepem 

	local cmd2 = 'openssl pkcs12 -nocerts -out ./temp_cert/' .. keyfilepem .. ' -in ./temp_cert/' .. filename_p12

	local cmd3 = 'openssl rsa -in ./temp_cert/' .. keyfilepem .. ' -out ./temp_cert/' .. keyfilepem


	local clear_cmd1 = 'echo > ./lua/cmd1.sh'
        local clear_cmd2 = 'echo > ./lua/cmd2.sh'
        local clear_cmd3 = 'echo > ./lua/cmd3.sh'
        os.execute( clear_cmd1 )
        os.execute( clear_cmd2 )
        os.execute( clear_cmd3 )
	
	local cmd11 = 'echo ' .. cmd1 .. " >> ./lua/cmd1.sh"
	local cmd22 = 'echo ' .. cmd2 .. " >> ./lua/cmd2.sh"
	local cmd33 = 'echo ' .. cmd3 .. " >> ./lua/cmd3.sh"

	os.execute( cmd1 )
	os.execute( cmd22 )
	os.execute( cmd33 )
	--Automatic input passwd
	os.execute( 'expect ./lua/passwd_file2.exp' )	
	os.execute( 'expect ./lua/passwd_file3.exp' )

	local remove_cmd = 'mv ./temp_cert/*pem ./cert/.'
	os.execute( remove_cmd )

	local file_path_a = "./cert/" .. cerfilepem
	local file_path_b = "./cert/" .. keyfilepem

	local cerpem_fd = io.open( file_path_a, rb )
	local keypem_fd = io.open( file_path_b, rb )
	if not cerpem_fd or not keypem_fd then
		ngx.log( ngx.ERR, "transform file met error" )
		return nil
	end

	local cerpem_length = cerpem_fd:seek( "end" )
	local keypem_length = keypem_fd:seek( "end" )
	cerpem_fd:close()
	keypem_fd:close()


	local opt = { ["redis_ip"] = redis_ip, ["redis_port"] = redis_port,[ "timeout"] = 3 }
        local redis_handler = redis_iresty:new( opt )
        if not redis_handler then
                ngx.log( ngx.ERR, "Connect redis failed" )
                return nil
        end

	local hash_key = "<KEY>_" .. bundleid
	
	if cerpem_length < limit or keypem_length < limit then
		send_file_status( 0, id, "文件格式错误" )
		local del_cmd = "rm -rf ./cert/cerfilepem keyfilepem"
		os.execute( del_cmd )

		local ok, err = redis_handler:hset( hash_key, "status", "false" )
		if not ok then
			ngx.log( ngx.ERR, "redis_handler:hset met error: ", err )
			return nil
		end
		--清除掉无用的文件以及在数据库的type字段中将文件的状态写进去
			
		return nil
	end 

	local ok, err = send_file_status( 1, id, "证书设置成功" )
	if not ok then
		ngx.log( ngx.ERR, "response error: ", err )
	end

	--将文件的状态写进数据库
	local del_cmd_a = "rm -rf ./temp_cert/*.cer"
	local del_cmd_b = "rm -rf ./temp_cert/*.p12"
	os.execute( del_cmd_a )
	os.execute( del_cmd_b )

	local ok, err = redis_handler:hset( hash_key, "status", "true" )
	if not ok then
		ngx.log( ngx.ERR, "redis_handler:hset key status---value true met error: ", err )
		return nil
	end

	return true
end

local function notify_download( pem_file_directory, cerfilepem, keyfilepem )
	if not pem_file_directory or not cerfilepem or not keyfilepem then
		return nil, "notify_download args is invalid"
	end

	local notify_protocol = {}
	notify_protocol["Body"]["Cerfilepem"] = cerfilepem
	notify_protocol["Body"]["Keyfilepem"] = keyfilepem
	notify_prococol["Body"]["Directory"] = pem_file_directory

	local strmsg = cjson.encode( notify_prococol )
	if strmsg == nil then
		return nil, "cjson.encode( notify_protocol ) failed"
	end	

	local host = "127.0.0.1"
	local port = "8003"
	local method = "POST"
	local url = host .. ':' .. port

	local httpc = http_iresty:new()
        local timeout = 6000
        httpc:set_timeout( timeout )
       
        local ret, err = httpc:request_uri( url, {
                        method = method,
                        body = strmsg

        })

        if not ret then
                ngx.log( ngx.ERR, "Http request met error: ", err )
                return nil, err, nil
        else
                if ret.status == 200 then
               		return true, "notify download service succ ..."
                else
                        ngx.log( ngx.ERR, "Status code=", ret.status )
                        return nil, ret.body, nil
                end

        end

	return nil, nil
end

local function get_pem_file()
	local ok, err, data  = pull_certificate()
	if not ok then
		ngx.log( ngx.ERR, "Pull_certificate met error: ", err )
		return nil
	end

	local tmp = cjson.encode( data )
	tmp = string.sub( tmp, 2, #tmp - 1 )
	
	local certs_infos = cjson.decode( tmp )
	if not certs_infos then
		ngx.log( ngx.ERR, "no certificates" )
		return nil
	end

	local id = certs_infos["id"]
	local source = certs_infos["source"]
	local bundleid = certs_infos["bundleId"]
	local version = certs_infos["versionType"]
	local expiretime = certs_infos["expireMillis"]
	local pushtime = certs_infos["timeMillis"]
	local userid = certs_infos["userId"]
	local ttype = certs_infos["type"]

	ngx.log( ngx.ERR, "id=", id )	
	ngx.log( ngx.ERR, "source=", source )
	ngx.log( ngx.ERR, "bundleid=", bundleid )
	ngx.log( ngx.ERR, "version=", version )
	ngx.log( ngx.ERR, "expiretime=", expiretime )
	ngx.log( ngx.ERR, "pushtime=", pushtime )
	ngx.log( ngx.ERR, "userid=", userid )
	ngx.log( ngx.ERR, "ttype=", ttype )
	ttype = "null"

	ngx.log( ngx.ERR, "w--------->", type( pushtime ) )
	utc_time = pushtime + 1
	if not id and not source and not boundleid and not version 
		and not expiretime and not pushtime and not userid then
		ngx.log( ngx.ERR, "No certificates to be update" )
		return nil
	end

	--store data in redis
	local opt = { ["redis_ip"] = redis_ip, ["redis_port"] = redis_port,[ "timeout"] = 3 }
	local redis_handler = redis_iresty:new( opt )
	if not redis_handler then
		ngx.log( ngx.ERR, "Connect redis failed" )
		return nil
	end

	local key = "<KEY>_" .. bundleid
	local key_id = "id"
	local key_source = "source"
	local key_bundleid = "bundleid"
	local key_version = "version"
	local key_expiretime = "expiretime"
	local key_pushtime = "pushtime"
	local key_userid = "userid"
	local key_status = "status"

	-- pattern == 0 add cert 
	-- pattern == 1 update cert
	-- default pattern=0
	local pattern = 0
	local cert, err = redis_handler:hgetall( key )
	if not cert then
		pattern = 0
		ngx.log( ngx.ERR, "Add a new certificate ..." )
	else
		pattern = 1
		ngx.log( ngx.ERR, "Update a certificate ..." )
	end

		
	local ok, err = redis_handler:hmset( key, key_id, id, key_source, source, key_bundleid, bundleid, key_version, version, 
						key_expiretime, expiretime, key_pushtime, pushtime, key_userid, userid, key_status, ttype )
	if not ok then
		ngx.log( ngx.ERR, "Write data to redis met error: ", err )
		return nil
	end

	ngx.log( ngx.ERR, "Write redis succ ... ... ... ... OK" )
	
	--download the cer and p12 file 
	local ok, err = download_certs( id, source )
	if not ok then
		ngx.log( ngx.ERR, "Download certificates met error: ", err )
		return nil
	end

	local ok, err = transform_file( bundleid, id )	
	if not ok then
		ngx.log( ngx.ERR, "Transform certificates to pem file failed" )
		return nil
	end
	
	
	local preffix_bundeleId = "<bundleId/>"
	local suffix_bundleId = "</bundleId>"
	local preffix_mustBe = "<mustBe/>"
	local suffix_mustBe = "</mustBe>\n"
	local preffix_time = "<time/>"
	local suffix_time = "</time>"
	local preffix_version = "<version/>"
	local suffix_version = "</version>"	
	ngx.update_time()
	local time = ngx.time()
	local ver = 0
	if version == "Develop" then
		ver = 1
	end

	local line = preffix_bundeleId .. bundleid .. suffix_bundleId .. preffix_time .. time .. suffix_time .. preffix_version .. ver .. suffix_version .. preffix_mustBe .. pattern .. suffix_mustBe
	
	if pattern == 0 then
		ngx.log( ngx.ERR, "new" )	
		local fd = io.open( "./cert/must_be.conf", "a+" )
		fd:write( line )
		fd:close()
	else
		local fd = io.open( "./cert/must_be.conf", "r")	
		local fd2 = io.open( "./cert/temp_be.conf", "a+")
	
		local table = {}	
		for l in fd:lines() do
			if l ~= "" then
				local pos_start = string.find( line, "<bundleId/>" )
                        	local pos_end = string.find( line, "</bundleId>" )
                        	local subname = string.sub( line, pos_start + 11 , pos_end - 1 )

				local from, to, err = ngx.re.find( l, bundleid, "jo" )
				if from == nil and to == nil then
					l = l .. "\n"
					fd2:write( l )	
				else
					fd2:write( line )
				end                        	
			end
		end			
		os.execute( "rm ./cert/must_be.conf" )
		io.popen( "mv ./cert/temp_be.conf ./cert/must_be.conf" )
	end

--[[	local ok, err = redis_handler:hmset( key, key_id, id, key_source, source, key_bundleid, bundleid, key_version, version, 
						key_expiretime, expiretime, key_pushtime, pushtime, key_userid, userid, key_status, ttype )
	if not ok then
		ngx.log( ngx.ERR, "Write data to redis met error: ", err )
		return nil
	end

	ngx.log( ngx.ERR, "Write redis succ ... ... ... ... OK" )
	
	--download the cer and p12 file 
	local ok, err = download_certs( id, source )
	if not ok then
		ngx.log( ngx.ERR, "Download certificates met error: ", err )
		return nil
	end

	local ok, err = transform_file( bundleid, id )	
	if not ok then
		ngx.log( ngx.ERR, "Transform certificates to pem file failed" )
		return nil
	end
]]--
--[[    warning [this code is not test]

	local cerfilepem = "Cer" .. bundleid .. ".pem"
        local keyfilepem = "Key" .. bundleid .. ".pem"
 
	local ok, err = notify_download( pem_file_directory, cerfilepem, keyfilepem )
	if not ok then
		ngx.log( ngx.ERR, "notify_download met error: ", err )
		return nil
	end
]]--	
	return true
end

timer_handler = function()
	get_pem_file()

	local ok, err = ngx.timer.at( delay, timer_handler )
	if not ok then
		ngx.log( ngx.ERR, "Create ngx timer met error: ", err )
		return
	end
end

local function process_start()
	local ok, err = ngx.timer.at( delay, timer_handler )
	if not ok then
		ngx.log( ngx.ERR, "Create ngx timer met error: ", err )
		return
	end
end


if ngx.var.server_port == "8002" then
	ngx.log( ngx.ERR, "PCS start successful" )
else
	ngx.log( ngx.ERR, "ngx.var.server_port invalid" )
	return
end

--get_pem_file()
process_start()
--[[test each module]]--
--download_certs( 53, "http://open.xmeye.net/iosupload/e0534f3240274897821a126be19b6d461531188480073.zip" )
--transform_file( "wangpeng" )
--[[local ok = send_file_status( 1, 2, "文件格式错误" )
if ok then
	ngx.log( ngx.ERR, "succ OK ..." )
end]]--
