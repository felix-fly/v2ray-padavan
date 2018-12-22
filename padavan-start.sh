#!/bin/sh

cd /etc/storage/v2ray

# limit vsz to 32mb (you can change it according to your device)
ulimit -v 32678
# Only use v2ray via pb config without v2ctl on low flash machine
./v2ray -config=./config.pb -format=pb &

# set iptables rules
iptables -t nat -N V2RAY
iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 192.168.1.0/24 -j RETURN
# From lans redirect to Dokodemo-door's local port
iptables -t nat -A V2RAY -s 192.168.1.0/24 -p tcp -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -j V2RAY
iptables -t nat -A OUTPUT -p tcp -j V2RAY
