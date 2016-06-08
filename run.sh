#!/bin/bash
set -e
echo "### clone repo. REPO_URL='${REPO_URL}' ###"
if [ ! -z "${REPO_URL}" ]; then
    [ -e "/repo_root" ] && rm -rf /repo_root
    git clone ${REPO_URL} /repo_root
    [ -d "/repo_root" ] && chown -R nginx.nginx /repo_root && ls -al /repo_root
fi

echo "#### add cron job. HEARTBEAT_URL='${HEARTBEAT_URL}', CRON_RUN_TIME='${CRON_RUN_TIME}' ####"
crond -P -s
echo '#!/bin/bash' > /run_cron.sh && chmod a+x /run_cron.sh
echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH' >> /run_cron.sh
echo 'echo "cron job run at $(date)"' >> /run_cron.sh
if [ ! -z "${HEARTBEAT_URL}" ]; then
    echo "curl ${HEARTBEAT_URL}" >> /run_cron.sh
fi
if [ ! -z "${REPO_URL}" ] && [ -d '/repo_root' ]; then
    echo 'cd /repo_root && git pull -r && chown -R nginx.nginx /repo_root' >> /run_cron.sh
fi
if [ ! -z "${CRON_RUN_TIME}" ]; then
    echo "${CRON_RUN_TIME} /run_cron.sh" | crontab
else
    echo '0 * * * * /run_cron.sh' | crontab
fi
crontab -l
echo -e "# run_cron.sh: \n$(cat /run_cron.sh)"

echo '#### root directory ####'
ls -al /

echo '#### process ####'
ps -ef

echo "#### start nginx. SERVER_NAME='${SERVER_NAME}', WWW_ROOT='${WWW_ROOT}' ####"
if [ ! -z "${SERVER_NAME}" ]; then
    sed -i "s/RG_SERVER_NAME/${SERVER_NAME}/g" /etc/nginx/conf.d/mysite.conf
else
    sed -i 's/RG_SERVER_NAME/localhost/g' /etc/nginx/conf.d/mysite.conf
fi
REAL_WWW_ROOT=""
if [ ! -z "${WWW_ROOT}" ]; then
    REAL_WWW_ROOT="${WWW_ROOT}"
elif [ ! -z "${REPO_URL}" ] && [ -d '/repo_root' ]; then
    REAL_WWW_ROOT="/repo_root"
else
    REAL_WWW_ROOT="/usr/share/nginx/html"
fi
if [ ! -z "${REAL_WWW_ROOT}" ]; then
    sed -i "s|RG_WWW_ROOT|${REAL_WWW_ROOT}|g" /etc/nginx/conf.d/mysite.conf
    if [ ! -f "${REAL_WWW_ROOT}/index.html" ]; then
        echo "nginx-docker index" > "${REAL_WWW_ROOT}/index.html"
        chown nginx.nginx "${REAL_WWW_ROOT}/index.html"
    fi
fi
nginx -g "daemon off;"
