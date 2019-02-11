#!/bin/sh

cd /etc/storage/v2ray

sleep 30

while true; do
    server=`ps | grep v2ray | grep -v grep`
    if [ ! "$server" ]; then
        ulimit -v 65536
        ./v2ray -config=./config.pb -format=pb &
        sleep 30
    fi
    sleep 30
done
