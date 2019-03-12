# v2ray-padavan

本文为在k2p路由器使用padavan(N56U/改华硕)固件安装配置v2ray的简单流程，相关的配置请参考官方文档。其他型号路由器理论上类似，可以参考。

为了方便小伙伴们，这里给出了一个[配置样例](./client-config.json)供参考。注意替换==包含的内容为你自己的配置，路由部分使用自定义的site文件，支持gw上网及各种广告过滤，site.dat文件可以从[v2ray-adlist](https://github.com/felix-fly/v2ray-adlist)获取最新版。

## 重要提示：

由于v2ray体积较大，需要自行编译路由器固件，增大storage分区的大小，可以先fork一下[https://github.com/hanwckf/rt-n56u](https://github.com/hanwckf/rt-n56u)，然后根据自己的需要修改配置文件，目前使用的是自编译的K2P_DRV，如果有需要可以在我的repositories里找[rt-n56u](https://github.com/felix-fly/rt-n56u)。

需要修改3个文件，本文将storage分区大小调整为6mb，修改时注意进制及单位：

* trunk/configs/templates/K2P_DRV.config [修改记录](https://github.com/felix-fly/rt-n56u/commit/cf50f6aca5b7ee3eaf4cbe634510692591b6d261)
* trunk/configs/boards/K2P/kernel-3.4.x.config [修改记录](https://github.com/felix-fly/rt-n56u/commit/d406d2113b93ac45c88436115d84422feb52e13d)
* trunk/user/scripts/mtd_storage.sh [修改记录](https://github.com/felix-fly/rt-n56u/commit/6fdc378d7866f421876827f252cc6ecb42cf42f3)

## 获取最新版本的v2ray

下载路由器硬件对应平台的压缩包到电脑并解压。以k2p为例的话是mipsle。解压后需要对原程序进行压缩，标准体积太大了~12mb，压缩使用upx，一个给程序加壳的小工具，压缩后不足4mb，这样才好放到路由器里。

**更新：在我的[v2ray-openwrt](https://github.com/felix-fly/v2ray-openwrt)里增加了压缩流程的相关说明，需要的话移步前去查看。**

## 生成pb文件

由于路由器内存较小，v2ray + v2ctl原始程序体积较大，即使压缩后也比较可观（约8mb）。使用pb文件时v2ray运行可以不依赖v2ctl，节约内存空间。使用pd的缺点是不能在路由中直接修改配置文件了，好在一般这个改动不会很频繁。

在电脑上使用v2ctl转换json配置文件，配置文件自行百度。

```
# linux系统下载linux版的v2ray
./v2ctl config < ./config.json > ./config.pb

# windows下安装git后也可以，下载windows版的v2ray
./v2ctl.exe config < ./config.json > ./config.pb
```

## 上传软件

一共需要4个文件：v2ray、config.pb、iptables.sh、check.sh

```
mkdir /etc/storage/v2ray
cd /etc/storage/v2ray
# 上传v2ray相关文件到该目录下
chmod +x v2ray
```

## 透明代理（iptables.sh）

透明代理部分使用iptables实现，如果不需要可自行删减修改。

规则中局域网的ip段（192.168.1.0）和v2ray监听的端口（12345）请结合实际情况修改。

```
#!/bin/sh

# set iptables rules
iptables -t nat -N V2RAY
iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 192.168.1.0/24 -j RETURN
# From lans redirect to Dokodemo-door's local port
iptables -t nat -A V2RAY -s 192.168.1.0/24 -p tcp -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -j V2RAY
iptables -t nat -A OUTPUT -p tcp -j V2RAY
```

[点此直接下载 iptables.sh文件](./iptables.sh)

## 启动/守护脚本（check.sh）

上次添加了守护脚本后，发现有时会出现多个进程同时存在的情况，导致cpu居高不下直至路由系统挂掉，猜测可能是脚本加在防火墙启动后调用导致，未证实。

```
#!/bin/sh

cd /etc/storage/v2ray

sleep 30

while true; do
    server=`ps aux | grep v2ray | grep -v grep`
    if [ ! "$server" ]; then
        ulimit -v 65536
        ./v2ray -config=./config.pb -format=pb &
        sleep 30
    fi
    sleep 30
done
```
[点此直接下载check.sh文件](./check.sh)

## 设置v2ray开机自动启动

**高级设置 -> 自定义设置 -> 脚本 -> 在路由器启动后执行:**

```
# 增加一行
/etc/storage/v2ray/check.sh &
```

**高级设置 -> 自定义设置 -> 脚本 -> 在防火墙规则启动后执行:**

```
# 增加一行
/etc/storage/v2ray/iptables.sh
```

## 保存软件及配置

padavan系统文件系统是构建在内存中的，重启后软件及配置会丢失，所以操作完成后，需要将v2ray及配置写入闪存。

**高级设置 -> 系统管理 -> 配置管理 -> 保存内部存储到闪存: 提交**

由于v2ray程序比较大，提交保存操作需要一定的时间，点过提交后请耐心等待1分钟，以确保写入成功。

如果一切顺利，重启路由器后你想要的v2ray依然在默默守护着你。Good luck!

## 更新记录
2019-03-12
* 修改了脚本及启动方式

2019-02-11
* 增加了守护脚本，自动重启v2ray

2018-12-10
* 增加了客户端配置样例，方便使用

