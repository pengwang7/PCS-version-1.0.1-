#!/bin/bash

config_path=`pwd`
nginx_path="/root/alarm_test/nginx/nginx/sbin/nginx"

${nginx_path} -p ${config_path} -c ${config_path}/conf/nginx.conf & 
