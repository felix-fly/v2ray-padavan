#!/bin/sh

cd /etc/storage/v2ray

sleep 5

while true; do
    server=`ps | grep -e "v2ray[[:space:]]\|v2ray$" | grep -v grep`
    if [ ! "$server" ]; then
        ulimit -v 65536
        # Use this with pb config
        ./v2ray -config=./config.pb -format=pb &
        # Use this with json config
        #./v2ray &
    fi
    sleep 60
done
