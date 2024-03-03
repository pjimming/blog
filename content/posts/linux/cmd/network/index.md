---
title: "Linux常用命令--网络篇"
subtitle: ""
date: 2024-03-03T18:22:42+08:00
lastmod: 2024-03-03T18:22:42+08:00
draft: false
author: "PanJM"
authorLink: "https://github.com/pjimming/"
description: ""
license: ""
images: []

tags: [linux,计算机网络]
categories: [linux]

featuredImage: "featured-image.png"
featuredImagePreview: "featured-image.png"

---
介绍Linux常用网络相关的命令
<!--more-->

---

## 网络的性能指标

1. *带宽*，表示链路的最大传输速率，单位是 b/s （比特 / 秒），带宽越大，其传输能力就越强。
2. *延时*，表示请求数据包发送后，收到对端响应，所需要的时间延迟。不同的场景有着不同的含义，比如可以表示建立 TCP 连接所需的时间延迟，或一个数据包往返所需的时间延迟。
3. *吞吐率*，表示单位时间内成功传输的数据量，单位是 b/s（比特 / 秒）或者 B/s（字节 / 秒），吞吐受带宽限制，带宽越大，吞吐率的上限才可能越高。
4. *PPS*，全称是 Packet Per Second（包 / 秒），表示以网络包为单位的传输速率，一般用来评估系统对于网络的转发能力。
5. *网络的可用性*，表示网络能否正常通信；
6. *并发连接数*，表示 TCP 连接数量；
7. *丢包率*，表示所丢失数据包数量占所发送数据组的比率；
8. *重传率*，表示重传网络包的比例；

## 查看网络配置

要想知道网络的配置和状态，我们可以使用 `ifconfig`​ 或者 `ip`​ 命令来查看。

由于 `ifconfig `​的 `net-tools`​ 网络包已不再维护，推荐使用 `ip`​ 命令。

### IP命令示例

```bash
# 网络接口的状态与配置
ip link show                     # 显示网络接口信息
ip link set eth0 up             # 开启网卡
ip link set eth0 down            # 关闭网卡
ip link set eth0 promisc on      # 开启网卡的混合模式
ip link set eth0 promisc offi    # 关闭网卡的混个模式
ip link set eth0 txqueuelen 1200 # 设置网卡队列长度
ip link set eth0 mtu 1400        # 设置网卡最大传输单元

# 网络接口IP地址信息
ip addr show     # 显示网卡IP信息
ip addr add 192.168.0.1/24 dev eth0 # 设置eth0网卡IP地址192.168.0.1
ip addr del 192.168.0.1/24 dev eth0 # 删除eth0网卡IP地址

# 路由表相关信息配置
ip route show # 显示系统路由
ip route add default via 192.168.1.254   # 设置系统默认路由
ip route list                 # 查看路由信息
ip route add 192.168.4.0/24  via  192.168.0.254 dev eth0 # 设置192.168.4.0网段的网关为192.168.0.254,数据走eth0接口
ip route add default via  192.168.0.254  dev eth0        # 设置默认网关为192.168.0.254
ip route del 192.168.4.0/24   # 删除192.168.4.0网段的网关
ip route del default          # 删除默认路由
ip route delete 192.168.1.0/24 dev eth0 # 删除路由
```

## 查看socket信息

我们可以使用 `netstat`​ 或者 `ss`​，这两个命令查看 socket、网络协议栈、网口以及路由表的信息。

两个命令都包含了 socket 的状态（*State*）、接收队列（*Recv-Q*）、发送队列（*Send-Q*）、本地地址（*Local Address*）、远端地址（*Foreign Address*）、进程 PID 和进程名称（*PID/Program name*）等。

接收队列（*Recv-Q*）和发送队列（*Send-Q*）比较特殊，在不同的 socket 状态。它们表示的含义是不同的。

当 socket 状态处于 `Established`​时：

- *Recv-Q* 表示 socket 缓冲区中还没有被应用程序读取的字节数；
- *Send-Q* 表示 socket 缓冲区中还没有被远端主机确认的字节数；

而当 socket 状态处于 `Listen`​ 时：

- *Recv-Q* 表示全连接队列的长度；
- *Send-Q* 表示全连接队列的最大长度；

### `netstat`​

#### 基本信息展示

```bash
# -n 以数字方式显示ip与端口
# -l 只显示Listen状态的socket
# -p 显示进程信息
➜  ~ netstat -nlp
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 127.0.0.1:34229         0.0.0.0:*               LISTEN      9254/node
tcp        0      0 127.0.0.1:45609         0.0.0.0:*               LISTEN      9343/node
tcp6       0      0 :::1313                 :::*                    LISTEN      16288/hugo
udp        0      0 127.0.0.1:323           0.0.0.0:*                           -
udp6       0      0 ::1:323                 :::*                                -
Active UNIX domain sockets (only servers)
Proto RefCnt Flags       Type       State         I-Node   PID/Program name     Path
unix  2      [ ACC ]     STREAM     LISTENING     26665    -                    /run/WSL/1_interop
unix  2      [ ACC ]     STREAM     LISTENING     18869    -                    /run/WSL/1_interop
unix  2      [ ACC ]     STREAM     LISTENING     20540    -                    /var/run/dbus/system_bus_socket
unix  2      [ ACC ]     SEQPACKET  LISTENING     23571    -                    /mnt/wslg/weston-notify.sock
unix  2      [ ACC ]     STREAM     LISTENING     17371    -                    /mnt/wslg/runtime-dir/wayland-0
unix  2      [ ACC ]     STREAM     LISTENING     17372    -                    /tmp/.X11-unix/X0
unix  2      [ ACC ]     STREAM     LISTENING     21543    -                    /mnt/wslg/runtime-dir/pulse/native
unix  2      [ ACC ]     STREAM     LISTENING     85688    -                    /run/WSL/9165_interop
unix  2      [ ACC ]     STREAM     LISTENING     495179   -                    /run/WSL/3624_interop
unix  2      [ ACC ]     STREAM     LISTENING     522857   -                    /run/WSL/3633_interop
unix  2      [ ACC ]     STREAM     LISTENING     21548    -                    /mnt/wslg/PulseServer
unix  2      [ ACC ]     STREAM     LISTENING     23578    -                    /tmp/dbus-Q2X6vqhXOW
unix  2      [ ACC ]     STREAM     LISTENING     80580    9343/node            /mnt/wslg/runtime-dir/vscode-ipc-6af430c3-a503-4265-877e-5ab3f607f5a0.sock
unix  2      [ ACC ]     STREAM     LISTENING     53922    9343/node            /mnt/wslg/runtime-dir/vscode-git-33e3af7794.sock
unix  2      [ ACC ]     STREAM     LISTENING     89624    9254/node            /mnt/wslg/runtime-dir/vscode-ipc-ffd4384c-903f-4fff-af02-e9e3884a301b.sock
unix  2      [ ACC ]     STREAM     LISTENING     89627    9254/node            /mnt/wslg/runtime-dir/vscode-ipc-093af220-9378-437a-8879-fc47c92425a2.sock
unix  2      [ ACC ]     STREAM     LISTENING     518896   -                    /mnt/wslg/PulseAudioRDPSource
unix  2      [ ACC ]     STREAM     LISTENING     536065   -                    /mnt/wslg/PulseAudioRDPSink
unix  2      [ ACC ]     STREAM     LISTENING     629995   -                    /run/WSL/16459_interop
```

#### 查看协议栈统计信息

​`netstat`​ 更为详细，显示了 TCP 协议的主动连接（*active connections openings*）、被动连接（*passive connection openings*）、失败重试（*failed connection attempts*）、发送（*segments send out*）和接收（*segments received*）的分段数量等各种信息。

```bash
➜  ~ netstat -s
Ip:
    Forwarding: 2
    135347 total packets received
    0 forwarded
    0 incoming packets discarded
    129806 incoming packets delivered
    129703 requests sent out
Icmp:
    324 ICMP messages received
    137 input ICMP message failed
    ICMP input histogram:
        destination unreachable: 263
        echo requests: 33
        echo replies: 28
    365 ICMP messages sent
    0 ICMP messages failed
    ICMP output histogram:
        destination unreachable: 299
        echo requests: 33
        echo replies: 33
IcmpMsg:
        InType0: 28
        InType3: 263
        InType8: 33
        OutType0: 33
        OutType3: 299
        OutType8: 33
Tcp:
    170 active connection openings
    288 passive connection openings
    3 failed connection attempts
    77 connection resets received
    7 connections established
    137529 segments received
    154330 segments sent out
    15 segments retransmitted
    0 bad segments received
    266 resets sent
Udp:
    47 packets received
    37 packets to unknown port received
    0 packet receive errors
    158 packets sent
    0 receive buffer errors
    0 send buffer errors
    IgnoredMulti: 674
UdpLite:
TcpExt:
    99 TCP sockets finished time wait in fast timer
    6799 delayed acks sent
    3 delayed acks further delayed because of locked socket
    Quick ack mode was activated 1109 times
    38886 packet headers predicted
    14754 acknowledgments not containing data payload received
    62405 predicted acknowledgments
    TCPSackRecovery: 1
    Detected reordering 6 times using SACK
    1 congestion windows fully recovered without slow start
    TCPLostRetransmit: 8
    2 fast retransmits
    TCPTimeouts: 12
    TCPLossProbes: 2
    TCPBacklogCoalesce: 250
    TCPDSACKOldSent: 1109
    TCPDSACKRecv: 1
    73 connections reset due to unexpected data
    4 connections reset due to early user close
    TCPSackShiftFallback: 5
    TCPRcvCoalesce: 728
    TCPOFOQueue: 63
    TCPChallengeACK: 3
    TCPSYNChallenge: 3
    TCPAutoCorking: 182
    TCPWantZeroWindowAdv: 2
    TCPSynRetrans: 12
    TCPOrigDataSent: 89318
    TCPHystartTrainDetect: 7
    TCPHystartTrainCwnd: 1656
    TCPKeepAlive: 9907
    TCPDelivered: 89203
    TCPAckCompressed: 40
    TcpTimeoutRehash: 12
    TcpDuplicateDataRehash: 994
    TCPDSACKRecvSegs: 2
IpExt:
    InBcastPkts: 674
    InOctets: 87064033
    OutOctets: 111649897
    InBcastOctets: 50719
    InNoECTPkts: 135568
Sctp:
    0 Current Associations
    0 Active Associations
    0 Passive Associations
    0 Number of Aborteds
    0 Number of Graceful Terminations
    0 Number of Out of Blue packets
    0 Number of Packets with invalid Checksum
    0 Number of control chunks sent
    0 Number of ordered chunks sent
    0 Number of Unordered chunks sent
    0 Number of control chunks received
    0 Number of ordered chunks received
    0 Number of Unordered chunks received
    0 Number of messages fragmented
    0 Number of messages reassembled
    0 Number of SCTP packets sent
    0 Number of SCTP packets received
```

### `ss`​

#### 查看基础信息

```bash
➜  ~ ss -tnp
State  Recv-Q  Send-Q            Local Address:Port              Peer Address:Port   Process
ESTAB  0       0                     127.0.0.1:34229                127.0.0.1:34364   users:(("node",pid=9254,fd=23))
ESTAB  0       0                     127.0.0.1:34364                127.0.0.1:34229   users:(("node",pid=3625,fd=18))
ESTAB  0       0                     127.0.0.1:34229                127.0.0.1:34368   users:(("node",pid=9343,fd=21))
ESTAB  0       0                     127.0.0.1:34368                127.0.0.1:34229   users:(("node",pid=3634,fd=18))
ESTAB  0       0                         [::1]:59648                    [::1]:1313
ESTAB  0       0         [::ffff:172.23.52.96]:1313      [::ffff:172.23.48.1]:55386   users:(("hugo",pid=16288,fd=12))
ESTAB  0       0                         [::1]:1313                     [::1]:59648   users:(("hugo",pid=16288,fd=9))
➜  ~   
```

#### 统计协议栈信息

​`ss`​ 只显示已经连接（*estab*）、关闭（*closed*）、孤儿（*orphaned*） socket 等简要统计。

```bash
➜  ~ ss -s
Total: 120
TCP:   10 (estab 7, closed 0, orphaned 0, timewait 0)

Transport Total     IP        IPv6
RAW       0         0         0
UDP       2         1         1
TCP       10        6         4
INET      12        7         5
FRAG      0         0         0

➜  ~                    
```

## 查看网络吞吐率和PPS

### 使用 `sar`​​ 获取网口统计信息

```bash
➜  ~ sar -n DEV  1
Linux 5.15.133.1-microsoft-standard-WSL2 (pjm2001)      03/03/24        _x86_64_        (16 CPU)

17:20:57        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
17:20:58           lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
17:20:58         eth0      1.00      0.00      0.21      0.00      0.00      0.00      1.00      0.00

17:20:58        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
17:20:59           lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
17:20:59         eth0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

17:20:59        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
17:21:00           lo      2.00      2.00      0.12      0.12      0.00      0.00      0.00      0.00
17:21:00         eth0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

17:21:00        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
17:21:01           lo      4.00      4.00      0.24      0.24      0.00      0.00      0.00      0.00
17:21:01         eth0      1.00      1.00      0.04      0.04      0.00      0.00      0.00      0.00
^C

Average:        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
Average:           lo      1.50      1.50      0.09      0.09      0.00      0.00      0.00      0.00
Average:         eth0      0.50      0.25      0.06      0.01      0.00      0.00      0.25      0.00
➜  ~
```

​`rxpck/s`​ 和 `txpck/s`​ 分别是接收和发送的 PPS，单位为包 / 秒。

​`rxkB/s`​ 和 `txkB/s`​ 分别是接收和发送的吞吐率，单位是 KB/ 秒。

​`rxcmp/s`​ 和 `txcmp/s`​ 分别是接收和发送的压缩数据包数，单位是包 / 秒。

### 使用 `ethtool`​ 查询带宽

```bash
➜  ~ ethtool eth0
Settings for eth0:
        Supported ports: [ ]
        Supported link modes:   Not reported
        Supported pause frame use: No
        Supports auto-negotiation: No
        Supported FEC modes: Not reported
        Advertised link modes:  Not reported
        Advertised pause frame use: No
        Advertised auto-negotiation: No
        Advertised FEC modes: Not reported
        Speed: 10000Mb/s
        Duplex: Full
        Port: Other
        PHYAD: 0
        Transceiver: internal
        Auto-negotiation: off
Cannot get wake-on-lan settings: Operation not permitted
        Current message level: 0x000000f7 (247)
                               drv probe link ifdown ifup rx_err tx_err
        Link detected: yes
➜  ~   
```

可以看`Speed`​字段，该网卡为万兆网卡

## 查看连通性与延时

使用 `ping`​ 命令

```bash
➜  ~ ping baidu.com -c 5
PING baidu.com (110.242.68.66) 56(84) bytes of data.
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=1 ttl=46 time=40.7 ms
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=2 ttl=46 time=46.8 ms
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=3 ttl=46 time=48.5 ms
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=4 ttl=46 time=45.8 ms
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=5 ttl=46 time=50.6 ms

--- baidu.com ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4067ms
rtt min/avg/max/mdev = 40.674/46.477/50.616/3.328 ms
➜  ~ 
```

显示的内容主要包含 `icmp_seq`​（ICMP 序列号）、`TTL`​（生存时间，或者跳数）以及 `time`​ （往返延时），而且最后会汇总本次测试的情况，如果网络没有丢包，`packet loss`​ 的百分比就是 0。

不过，需要注意的是，`ping`​ 不通服务器并不代表 HTTP 请求也不通，因为有的服务器的防火墙是会禁用 ICMP 协议的。

## 防火墙设置

要在 Linux 上禁用一个 IP 或者某个 TCP 端口，你可以使用防火墙软件，如 `iptables`​ 或者 `firewalld`​。

### 使用 iptables：

1. **禁用一个 IP：**
  
  ```bash
  sudo iptables -A INPUT -s 目标IP -j DROP
  ```
  
  这个命令将来自目标 IP 的所有入站流量直接丢弃，从而禁止了该 IP 的访问。
  
2. **禁用某个 TCP 端口：**
  
  ```bash
  sudo iptables -A INPUT -p tcp --dport 端口号 -j DROP
  ```
  
  这个命令将来自指定 TCP 端口的所有入站流量直接丢弃，从而禁止了该端口的访问。
  

### 使用 firewalld：

1. **禁用一个 IP：**
  
  ```bash
  sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="目标IP" drop'
  sudo firewall-cmd --reload
  ```
  
  这个命令将来自目标 IP 的所有流量直接丢弃，从而禁止了该 IP 的访问。
  
2. **禁用某个 TCP 端口：**
  
  ```bash
  sudo firewall-cmd --permanent --add-port=端口号/tcp
  sudo firewall-cmd --reload
  ```
  
  这个命令将来自指定 TCP 端口的所有流量直接丢弃，从而禁止了该端口的访问。
  