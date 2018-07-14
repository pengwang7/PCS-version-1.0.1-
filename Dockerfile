#DOCKERFILE
FROM daocloud.io/cloudwang/openresty:1.0.0
MAINTAINER wangpeng<wangpeng19960620@163.com>

COPY 	supervisord.conf /etc/supervisord.conf
COPY 	pcs/ /xm_workspace/xmcloud3.0/OpenrestyPullCertsServer/

RUN 	chmod 777 /xm_workspace/xmcloud3.0/OpenrestyPullCertsServer/*

WORKDIR /xm_workspace/xmcloud3.0/OpenrestyPullCertsServer/
CMD	["ls"]

EXPOSE 8001 8002

