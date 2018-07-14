local remote_host = "106.14.78.92"
local remote_port = "8002"
--if flag == 0 (distrubution)
--if flag == 1 (develop)
function apns_start( unix_path, cerfile, keyfile, flag )
	if not unix_path or not cerfile or not keyfile then
		ngx.log( ngx.ERR, "invalid args ... ... " )
		return false, "invalid args ..."
	end

	local start_cmd = "../apns_server -u " .. "/tmp/apns_unixsocket_" .. unix_path .. " -p " .. "..certs/" .. cerfile .. " -k " .. "../certs/" .. keyfile .. " -s " .. flag

	io.popen( start_cmd )

	return true, nil
end

function get_time_from_list( subname )
	local fd = io.open( "./list/oldfilelist.txt", "r" )
	if not fd then
		return false, "oldfile not exist"
	end

	local time = 0
	for line in fd:lines() do
		if line ~= "" then 
			local from, to, err = ngx.re.find( line, subname, "jo" )
			if from ~= nil and to ~= nil then
				local f, t, e = ngx.re.find( line, "<time/>", "jo")
				local f1, t1, e1 = ngx.re.find( line, "</time>", "jo" )
				time = string.sub( line, t + 1, f1 - 1 )
			end		
		end
	end

	if time == nil then
		ngx.log( ngx.ERR, "get old time from list met failed" )
	end

	return time
end

---test------------------------------------
function write_supervisord_conf_file( subname, version )
	local filepath = "./list/" .. subname
	local filename = "/supervisord.conf"
	local touch_cmd = "touch " .. filepath .. filename
	os.execute( touch_cmd )

	local fd = io.open( filepath .. filename, "a+" )		
	if not fd then
		local err = "cat't open supervisord.conf file"
		ngx.log( ngx.ERR, "io.open met error:", err )
		return false, err
	end

	local cerfilename = "Cer" .. subname .. ".pem"
	local keyfilename = "Key" .. subname .. ".pem"
	local common_path = "./list/" .. subname .. "/"
	local header1 = "[supervisord]\n"
	local header2 = "nodaemon=true\n"
	local line1 = "[program:apns_" .. subname .. "]\n"
	local line2 = "directory=/xm_workspace/xmcloud3.0/apns_server/" .. subname .. "\n"
	local line3 = "command=/xm_workspace/xmcloud3.0/apns_server/apns_server -u /tmp/apns_unixsocket_" 
	local line4 = line3 .. subname .. " -p " .. common_path .. cerfilename .. " -k " .. common_path .. keyfilename .. " -s " .. version
	
	fd:write( header1 )
	fd:write( header2 )
	fd:write( line1 )
	fd:write( line2 )
	fd:write( line4 )

	fd:close()

	return true, nil	
end
----------------------------------------------

function supervisord_clt_update( subname )
	local start_cmd = "supervisorctl start apns_" .. subname
	local ok = io.popen( start_cmd )
	if not ok then
		ngx.log( ngx.ERR, "error:", start_cmd )
		return false, "supervisorctl start apns_" .. subname .. " failed"
	end

	return true, nil
end

function download_pem_file( subname, flag, version, time )
	if subname == nil then
		return false, "download_pem_file invalid args"
	end

	local s = 0
	local cerfilename = "Cer" .. subname .. ".pem"
	local keyfilename = "Key" .. subname .. ".pem"

	local download_cmd_cer = "curl -X GET http://" .. remote_host .. ":" .. remote_port .. "/" .. cerfilename .. " > ./list/" .. subname .. "/" .. cerfilename
	local download_cmd_key = "curl -X GET http://" .. remote_host .. ":" .. remote_port .. "/" .. keyfilename .. " > ./list/" .. subname .. "/" .. keyfilename

	ngx.log( ngx.ERR, "ffffffffffffffffff=", flag )


	if flag == "0" then
		s = 1
		local make_dir_cmd = "mkdir ./list/" .. subname
		os.execute( make_dir_cmd )
		os.execute( "rm -rf ./list/" .. subname .. "/*" )
		os.execute( download_cmd_cer )
		os.execute( download_cmd_key )
	else
		local old_time = get_time_from_list( subname ) 
                ngx.log( ngx.ERR, "old_time=", old_time )
                if time ~= old_time then
			s = 2
                        ngx.log( ngx.ERR, "gengxinlalala" )
 			os.execute( "rm -rf ./list/" .. subname .. "/*.pem" )
			os.execute( download_cmd_cer )
                        os.execute( download_cmd_key )
                else
			s = 3
		end
	end
	
	if s == 1 or s == 2 then
		local path = "./list/" .. subname .. "/"
                local fd1 = io.open( path .. cerfilename )
                local fd2 = io.open( path .. keyfilename )

                if not fd1 then
                        os.execute( "rm -rf ./list/" .. subname )
                        os.execute( "rm -rf ./list/filelist.txt" )
                        ngx.log( ngx.ERR, "download cerfilename failed" )
                        return false, "download cerfilename failed"
                end 

                if not fd2 then
                        os.execute( "rm -rf ./list/" .. subname )
                        os.execute( "rm -rf ./list/filename.txt" )
                        ngx.log( ngx.ERR, "download keyfilename failed" )
                        return false, "download keyfilename failed"
                end


                local length1 = fd1:seek( "end" )
                local length2 = fd2:seek( "end" )
                if length1 < 500 or length2 < 500 then
                        local rm_cmd = "rm -rf ./list" .. subname .. "/" .. "*.pem"
                        local rm_dir_cmd = "rm -rf ./list" .. subname
                        os.execute( rm_cmd )
                        os.execute( "rm ./list/filelist.txt" )
                        io.popen( rm_dir_cmd )
                        return false, "download met error: file size < 500"
                end

                fd1:close()
                fd2:close()
	
		if s == 1 then
			local ok, err = write_supervisord_conf_file( subname, version )
			if not ok then
				ngx.log( ngx.ERR, "write_supervisord_conf_file met error:", err )
				return false, err
			end
		end

	local ok, err = supervisord_clt_update( subname )
		if not ok then
			ngx.log( ngx.ERR, "supervisord_ctl_update met error:", err )
			return false, err
		end
	end 


	return true, nil
end

function get_cert_list()
	local list_cmd = "curl -X GET http://" .. remote_host .. ":" .. remote_port .. "/must_be.conf" .. " > ./list/filelist.txt"
	os.execute( list_cmd )

	local fd = io.open( "./list/filelist.txt", "r" )
	if not fd then
		return false, "open ./list/filelist.txt file failed"
	end

	for line in fd:lines() do
		if line ~= "" and line ~= nil then
			ngx.log( ngx.ERR, "each line=", line )
			
			local pos_start = string.find( line, "<bundleId/>" )
			local pos_end = string.find( line, "</bundleId>" )
			local subname = string.sub( line, pos_start + 11, pos_end - 1 )
			ngx.log( ngx.ERR, "subname=", subname )

			local pos_start = string.find( line, "<time/>" )	
			local pos_end = string.find( line, "</time>" )		
			local time = string.sub( line, pos_start + 7, pos_end - 1 )
			ngx.log( ngx.ERR, "time=", time )

			local pos_start = string.find( line, "<mustBe/>")
			local pos_end = string.find( line, "</mustBe>" )
			local mustbe = string.sub( line, pos_start + 9, pos_end - 1 )
			ngx.log( ngx.ERR, "mustbe=", mustbe )

			local pos_start = string.find( line, "<version/>" )			
			local pos_end = string.find( line, "</version>" )
			local version = string.sub( line, pos_start + 10, pos_end - 1 )
			ngx.log( ngx.ERR, "version=", version )

			local ok, err = download_pem_file( subname, mustbe, version, time )
			if not ok then
				return false, err
			end
		end
	end
	
	os.execute( "rm -rf ./list/oldfilelist.txt" )
	io.popen( "mv ./list/filelist.txt ./list/oldfilelist.txt" )
--[[
	local ok, err = apns_start()
	if not ok then
		ngx.log( ngx.ERR, "apns_start met error: ", err )
	end
]]--
	ngx.log( ngx.ERR, "apns_start succ ... ... ... ... " )

	return true, nil
end


function supervisord_update()
	return true, nil
end

function process_start()
	local ok, err = get_cert_list()
	if not ok then
		ngx.log( ngx.ERR, "get_file_list met error: ", err )
	end

	local ok, err = supervisord_update()
	if not ok then
		ngx.log( ngx.ERR, "supervisord_update met error: ", err )
	end
end

process_start()
