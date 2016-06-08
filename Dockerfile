FROM centos:centos7
MAINTAINER test01wrk test01wrk@163.com

COPY run.sh /
COPY etc /etc

RUN yum update && yum install -y cronie nginx git \
    && mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf_bak \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && chmod a+x /run*.sh

EXPOSE 80

ENV REPO_URL="" HEARTBEAT_URL="" CRON_RUN_TIME="" SERVER_NAME="" WWW_ROOT=""

ENTRYPOINT ["/run.sh"]
