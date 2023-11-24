#!/bin/bash

GITHUB_REF_NAME=$*

PROVIDER=$(echo $GITHUB_REF_NAME | awk -F '/' '{print$1}')
DOMAINS=$(echo $GITHUB_REF_NAME | awk -F '/' '{print$2}')

envsubst </root/.mc/mc.config.tmpl >/root/.mc/config.json
envsubst </root/.config/rclone/rclone.conf.tmpl >/root/.config/rclone/rclone.conf

EMAIL=${EMAIL:-"sys-ops@test.com"}

for domain in $(echo $DOMAINS | sed 's/,/ /g'); do
    {
        _domain=$(echo $domain | sed 's/wild./*./')
        DOMAIN_LIST="${DOMAIN_LIST} --domains=${_domain}"
    }
done

PARAMS="--dns.resolvers ${RESOLVERS:-223.5.5.5} --key-type rsa2048 --accept-tos ${DOMAIN_LIST} "

function aliyun() {
    /usr/bin/lego --email="${EMAIL}" ${PARAMS} --path=$(pwd) --dns alidns run
}

function qcloud() {
    /usr/bin/lego --email="${EMAIL}" ${PARAMS} --path=$(pwd) --dns dnspod run
}

function cfdns() {
    #/usr/bin/lego --email="${EMAIL}" ${PARAMS} --path=$(pwd) --dns cloudflare run
    lego --email="${EMAIL}" ${PARAMS} --path=$(pwd) --dns cloudflare run
}

function archive() {
    ls certificates/*
    tar zcf ssl.tgz certificates && mc cp ssl.tgz cos/ops-software/nginx-certs/ && {

        TGZ=$S3_EP/nginx-certs/${DOMAINS}.tgz

        echo ""
        echo $TGZ
        echo "wget -c $TGZ"

    }

}

case $PROVIDER in
aliyun)
    aliyun
    ;;
cf)
    cfdns
    ;;
qcloud)
    export DNSPOD_HTTP_TIMEOUT=${DNSPOD_HTTP_TIMEOUT:-300}
    qcloud
    ;;
esac

archive



cat /root/.mc/config.json
cat /root/.config/rclone/rclone.conf