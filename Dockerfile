#DOCKERFILE
FROM daocloud.io/cloudwang/openresty:1.0.0
MAINTAINER wangpeng<wangpeng19960620@163.com>

COPY 	supervisord.conf /etc/supervisord.conf
COPY 	pcs/ /xm_workspace/xmcloud3.0/pcs/

RUN 	chmod 777 /xm_workspace/xmcloud3.0/pcs/*

WORKDIR /xm_workspace/xmcloud3.0/pcs/
CMD	["supervisord"]

EXPOSE 8001 8002

