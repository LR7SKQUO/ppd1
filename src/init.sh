#!/bin/sh
mkdir -p /data
rm /tmp/*.conf >/dev/null 2>&1
rm /tmp/*.toml >/dev/null 2>&1
echo =====PaoPaoDNS docker start=====
echo images build time : {bulidtime}
if [ ! -f /new.lock ]; then
    echo New version install ! Try clean...
    rm -rf /data/redis.conf >/dev/null 2>&1
    rm -rf /data/unbound.conf >/dev/null 2>&1
    rm -rf /data/mosdns.yaml >/dev/null 2>&1
    rm -rf /data/dnscrypt.toml >/dev/null 2>&1
    rm -rf /data/Country-only-cn-private.mmdb >/dev/null 2>&1
    rm -rf /data/global_mark.dat >/dev/null 2>&1
    rm -rf /data/dnscrypt-resolvers >/dev/null 2>&1
    touch /new.lock
fi

if [ ! -f /data/unbound.conf ]; then
    cp /usr/sbin/unbound.conf /data/
fi
if [ ! -f /data/unbound_custom.conf ]; then
    cp /usr/sbin/unbound_custom.conf /data/
fi
if [ ! -f /data/redis.conf ]; then
    cp /usr/sbin/redis.conf /data/
fi
if [ "$UPDATE" != "no" ]; then
    crond
    if [ ! -f /etc/periodic/"$UPDATE" ]; then
        rm -rf /etc/periodic/*
        mkdir -p /etc/periodic/"$UPDATE"
        cp /usr/sbin/data_update.sh /etc/periodic/"$UPDATE"
    fi
fi
CORES=$(grep -c ^processor /proc/cpuinfo)
if [ "$(ulimit -n)" -gt 999999 ]; then
    echo "ulimit adbove 1000000."
else
    ulimit -SHn 1048576
    echo ulimit:$(ulimit -n)
fi
lim=$(ulimit -n)
POWCORES=2
if [ "$CORES" -gt 3 ]; then
    POWCORES=4
fi
if [ "$CORES" -gt 6 ]; then
    POWCORES=8
fi
if [ "$CORES" -gt 12 ]; then
    POWCORES=16
fi
if [ "$CORES" -gt 24 ]; then
    POWCORES=32
fi
if [ "$CORES" -gt 48 ]; then
    POWCORES=64
fi
if [ "$CORES" -gt 96 ]; then
    POWCORES=128
fi
FDLIM=$((lim / (2 * CORES) - CORES * 3))
if [ "$FDLIM" -gt 4096 ]; then
    FDLIM=4096
fi
free -m
free -h
MEMSIZE=$(free -m | grep Mem | grep -Eo "[0-9]+" | tail -1)
prefPC=1
echo MEMSIZE:"$MEMSIZE"
# min:50m suggest:16G
MEM1=100k
MEM2=200k
MEM3=200
MEM4=16mb
MSCACHE=1024
safemem=yes
if [ "$SAFEMODE" = "yes" ]; then
    echo safemode enable!
    FDLIM=1
else
    if [ "$MEMSIZE" -gt 500 ]; then
        MEM1=50m
        MEM2=100m
        MEM4=100mb
        prefPC=9
    fi
	if [ "$MEMSIZE" -gt 1000 ]; then
        safemem=no
        MEM1=100m
        MEM2=200m
        MEM4=200mb
        MSCACHE=5120
        prefPC=18
    fi
    #if [ "$MEMSIZE" -gt 2000 ]; then
	if [ "$MEMSIZE" -gt 1500 ]; then
        safemem=no
        MEM1=200m
        MEM2=400m
        MEM4=450mb
        MSCACHE=10240
        prefPC=41
    fi
    if [ "$MEMSIZE" -gt 2500 ]; then
        MEM1=220m
        MEM2=450m
        MEM3=500000
        MEM4=750mb
        prefPC=68
    fi
    if [ "$MEMSIZE" -gt 4000 ]; then
        MEM1=400m
        MEM2=800m
        MEM4=900mb
        prefPC=82
    fi
    if [ "$MEMSIZE" -gt 6000 ]; then
        MEM1=500m
        MEM2=1000m
        MEM4=1500mb
        MSCACHE=102400
        prefPC=100
    fi
    if [ "$MEMSIZE" -gt 8000 ]; then
        MEM1=800m
        MEM2=1600m
        MEM3=1000000
        MEM4=1800mb
        MSCACHE=1024000
    fi
    if [ "$MEMSIZE" -gt 12000 ]; then
        MEM1=1000m
        MEM2=2000m
        MEM3=1000000
        MEM4=3000mb
    fi
    if [ "$MEMSIZE" -gt 16000 ]; then
        MEM1=1500m
        MEM2=3000m
        MEM3=10000000
        MEM4=4500mb
    fi
fi
if [ "$MEM1" = "100k" ]; then
    echo "[Warning] LOW MEMORY!"
    CORES=1
    POWCORES=1
    FDLIM=1
fi
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
ETHIP=$(ip -o -4 route get 1.0.0.1 | grep -Eo "$IPREX4" | tail -1)
if [ -z "$ETHIP" ]; then
    ETHIP="127.0.0.2"
fi
if [ -z "$DNS_SERVERNAME" ]; then
    DNS_SERVERNAME="PaoPaoDNS,blog.03k.org"
fi
if [ -z "$DNSPORT" ]; then
    DNSPORT="53"
fi
if [ -z "$AUTO_FORWARD" ]; then
    AUTO_FORWARD="no"
fi

echo ====ENV TEST==== >/tmp/env.conf
echo MEM:"$MEM1" "$MEM2" "$MEM3" "$MEM4" >>/tmp/env.conf
echo prefPC:"$prefPC" >>/tmp/env.conf
echo CORES:-"$CORES""-" >>/tmp/env.conf
echo POWCORES:-"$POWCORES""-" >>/tmp/env.conf
echo ulimit :-"$(ulimit -n)""-" >>/tmp/env.conf
echo FDLIM :-"$FDLIM""-" >>/tmp/env.conf
echo TZ:-"$TZ""-" >>/tmp/env.conf
echo UPDATE:-"$UPDATE""-" >>/tmp/env.conf
echo DNS_SERVERNAME:-"$DNS_SERVERNAME""-" >>/tmp/env.conf
echo SERVER_IP:-"$SERVER_IP""-" >>/tmp/env.conf
echo ETHIP:-"$ETHIP""-" >>/tmp/env.conf
echo DNSPORT:-"$DNSPORT""-" >>/tmp/env.conf
echo SOCKS5:-"$SOCKS5""-" >>/tmp/env.conf
echo CNAUTO:-"$CNAUTO""-" >>/tmp/env.conf
echo IPV6:-"$IPV6""-" >>/tmp/env.conf
echo CNFALL:-"$CNFALL""-" >>/tmp/env.conf
echo CUSTOM_FORWARD:-"$CUSTOM_FORWARD""-" >>/tmp/env.conf
echo AUTO_FORWARD:-"$AUTO_FORWARD""-" >>/tmp/env.conf
echo AUTO_FORWARD_CHECK:-"$AUTO_FORWARD_CHECK""-" >>/tmp/env.conf
echo USE_MARK_DATA:-"$USE_MARK_DATA""-" >>/tmp/env.conf
echo RULES_TTL:-"$RULES_TTL""-" >>/tmp/env.conf
echo CN_TRACKER:-"$CN_TRACKER""-" >>/tmp/env.conf
echo USE_HOSTS:-"$USE_HOSTS""-" >>/tmp/env.conf
echo HTTP_FILE:-"$HTTP_FILE""-" >>/tmp/env.conf
echo SAFEMODE:-"$SAFEMODE""-" >>/tmp/env.conf
echo QUERY_TIME:-"$QUERY_TIME""-" >>/tmp/env.conf
echo PLATFORM:-"$(uname -a)""-" >>/tmp/env.conf
echo ====ENV TEST==== >>/tmp/env.conf
cat /tmp/env.conf

sed "s/{CORES}/$CORES/g" /data/unbound.conf | sed "s/{POWCORES}/$POWCORES/g" | sed "s/{FDLIM}/$FDLIM/g" | sed "s/{MEM1}/$MEM1/g" | sed "s/{MEM2}/$MEM2/g" | sed "s/{MEM3}/$MEM3/g" | sed "s/{ETHIP}/$ETHIP/g" | sed "s/{DNS_SERVERNAME}/$DNS_SERVERNAME/g" >/tmp/unbound.conf
if [ "$safemem" = "no" ]; then
    sed -i "s/#safemem//g" /tmp/unbound.conf
else
    sed -i "s/#lowrmem//g" /tmp/unbound.conf
fi
if echo "$SERVER_IP" | grep -Eoq "[.0-9]+"; then
    sed -i "s/{SERVER_IP}/$SERVER_IP/g" /tmp/unbound.conf
    sed -i "s/#serverip-enable//g" /tmp/unbound.conf
fi
if [ "$CNAUTO" != "no" ]; then
    DNSPORT="5301"
    if [ ! -f /data/mosdns.yaml ]; then
        cp /usr/sbin/mosdns.yaml /data/
    fi
    if [ ! -f /data/Country-only-cn-private.mmdb ]; then
        /usr/sbin/data_update.sh ex_mmdb
    fi
    cat /data/Country-only-cn-private.mmdb >/tmp/Country.mmdb
    if [ ! -f /data/dnscrypt.toml ]; then
        cp /usr/sbin/dnscrypt.toml /data/
    fi
    if [ ! -f /data/dnscrypt-resolvers/public-resolvers.md ]; then
        mkdir -p /data/dnscrypt-resolvers/
        cp /usr/sbin/dnscrypt-resolvers/* /data/dnscrypt-resolvers/
    fi
    if [ ! -f /data/force_nocn_list.txt ]; then
        cp /usr/sbin/force_nocn_list.txt /data/
    fi
    if [ ! -f /data/force_cn_list.txt ]; then
        cp /usr/sbin/force_cn_list.txt /data/
    fi
    if echo "$SOCKS5" | grep -Eoq ":[0-9]+"; then
        SOCKS5=$(echo "$SOCKS5" | sed 's/"//g')
        sed "s/#socksok//g" /data/dnscrypt.toml | sed "s/{SOCKS5}/$SOCKS5/g" | sed -r "s/listen_addresses.+/listen_addresses = ['0.0.0.0:5303']/g" >/data/dnscrypt-resolvers/dnscrypt_socks.yaml
        dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt_socks.yaml >/dev/null 2>&1 &
        sed "s/{DNSPORT}/5304/g" /tmp/unbound.conf | sed "s/#CNAUTO//g" | sed "s/#socksok//g" >/tmp/unbound_forward.conf
        sed "s/#socksok//g" /data/mosdns.yaml >/tmp/mosdns.yaml
        sleep 5
    else
        sed "s/{DNSPORT}/5304/g" /tmp/unbound.conf | sed "s/#CNAUTO//g" | sed "s/#nosocks//g" >/tmp/unbound_forward.conf
        sed "s/#nosocks//g" /data/mosdns.yaml >/tmp/mosdns.yaml
    fi
    if [ "$IPV6" = "yes" ]; then
        sed -i "s/#ipv6raw//g" /tmp/mosdns.yaml
        sed -i "s/#ipv6ok//g" /tmp/mosdns.yaml
    fi
    if [ "$IPV6" = "only6" ]; then
        sed -i "s/#ipv6raw//g" /tmp/mosdns.yaml
        sed -i "s/#ipv6ok//g" /tmp/mosdns.yaml
        sed -i "s/#ipv6only6//g" /tmp/mosdns.yaml
    fi
    if [ "$IPV6" = "no" ]; then
        sed -i "s/#ipv6raw//g" /tmp/mosdns.yaml
    fi
    if [ "$CNFALL" = "yes" ]; then
        sed -i "s/#cnfall//g" /tmp/mosdns.yaml
    else
        sed -i "s/#nofall//g" /tmp/mosdns.yaml
    fi
    if echo "$CUSTOM_FORWARD" | grep -Eoq ":[0-9]+"; then
        CUSTOM_FORWARD=$(echo "$CUSTOM_FORWARD" | sed 's/"//g')
        sed -i "s/#customforward-seted//g" /tmp/mosdns.yaml
        sed -i "s/{CUSTOM_FORWARD}/$CUSTOM_FORWARD/g" /tmp/mosdns.yaml
        if [ ! -f /data/force_forward_list.txt ]; then
            cp /usr/sbin/force_forward_list.txt /data/
        fi
        if [ "$AUTO_FORWARD" = "yes" ]; then
            sed -i "s/#autoforward-yes//g" /tmp/mosdns.yaml
            if [ "$AUTO_FORWARD_CHECK" = "yes" ]; then
                sed -i "s/#autoforward-check//g" /tmp/mosdns.yaml
            else
                sed -i "s/#autoforward-nocheck//g" /tmp/mosdns.yaml
            fi
        fi
    fi
    if [ "$AUTO_FORWARD" = "no" ]; then
        sed -i "s/#autoforward-no//g" /tmp/mosdns.yaml
    fi
    if [ "$CN_TRACKER" = "yes" ]; then
        sed -i "s/#cntracker-yes//g" /tmp/mosdns.yaml
        /usr/sbin/watch_list.sh load_trackerslist
    fi
    if [ "$USE_MARK_DATA" = "yes" ]; then
        sed -i "s/#global_mark_yes//g" /tmp/mosdns.yaml
        if [ ! -f /data/global_mark.dat ]; then
            cp /usr/sbin/global_mark.dat /data/
        fi
        /usr/sbin/watch_list.sh load_mark_data
    else
        sed -i "s/#global_mark_no//g" /tmp/mosdns.yaml
    fi
    #convert hosts
    if [ "$USE_HOSTS" = "yes" ]; then
        grep -vE "^#" /etc/hosts | grep . | sort -u >/tmp/hosts.cp.gen
        echo "" >>/tmp/hosts.cp.gen
        echo "" >>/tmp/hosts.cp.gen
        echo "" >/tmp/hosts.txt
        while read line; do
            record=$(echo "$line" | grep -Eo "[.:a-f0-9]+" | head -1)
            domain=$(echo "$line" | grep -Eo "[-_.a-zA-Z0-9]+" | tail -1)
            echo "$domain" "$record" >>/tmp/hosts.txt
        done </tmp/hosts.cp.gen
        rm /tmp/hosts.cp.gen
        sed -i "s/#usehosts-yes//g" /tmp/mosdns.yaml
        sed -i "s/#usehosts-enable//g" /tmp/mosdns.yaml
    fi
    if echo "$SERVER_IP" | grep -Eoq "[.0-9]+"; then
        sed -i "s/#usehosts-yes//g" /tmp/mosdns.yaml
        sed -i "s/#serverip-enable//g" /tmp/mosdns.yaml
        sed -i "s/{SERVER_IP}/$SERVER_IP/g" /tmp/mosdns.yaml
    fi
    if [ -f /data/force_nocn_list.txt ]; then
        sed 's/\r$//' /data/force_nocn_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_nocn_list.txt
    fi
    if [ -f /data/force_cn_list.txt ]; then
        sed 's/\r$//' /data/force_cn_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_cn_list.txt
    fi
    if [ -f /data/force_forward_list.txt ]; then
        sed 's/\r$//' /data/force_forward_list.txt | grep -E "^[a-zA-Z0-9]" >/tmp/force_forward_list.txt
    fi
    RULES_TTL=$(echo "$RULES_TTL" | grep -Eo "[0-9]+|head -1")
    if [ -z "$RULES_TTL" ]; then
        RULES_TTL=0
    fi
    if [ "$RULES_TTL" -gt 0 ]; then
        sed "s/#ttl_rule_ok//g" /data/dnscrypt.toml >/data/dnscrypt-resolvers/dnscrypt.toml
        sed -i "s/#ttl_rule_ok//g" /tmp/mosdns.yaml
        sed -i "s/{RULES_TTL}/$RULES_TTL/g" /tmp/mosdns.yaml
        /usr/sbin/watch_list.sh load_ttl_rules
    else
        cp /data/dnscrypt.toml /data/dnscrypt-resolvers/dnscrypt.toml
    fi
    if [ "$HTTP_FILE" = "yes" ]; then
        sed -i "s/#http_file_yes//g" /tmp/mosdns.yaml
    fi
    sed -i "s/{MSCACHE}/$MSCACHE/g" /tmp/mosdns.yaml
    sed -i '/^#/d' /tmp/mosdns.yaml
    dnscrypt-proxy -config /data/dnscrypt-resolvers/dnscrypt.toml >/dev/null 2>&1 &
    unbound -c /tmp/unbound_forward.conf -p >/dev/null 2>&1 &
    mosdns start -d /tmp -c mosdns.yaml &
fi
sed "s/{DNSPORT}/$DNSPORT/g" /tmp/unbound.conf >/tmp/unbound_raw.conf
unbound -c /tmp/unbound_raw.conf -p >/dev/null 2>&1 &
#Unexpected fallback while updating data
echo "nameserver 127.0.0.1" >/etc/resolv.conf
echo "nameserver 223.5.5.5" >>/etc/resolv.conf
echo "nameserver 1.0.0.1" >>/etc/resolv.conf
/usr/sbin/watch_list.sh &
/usr/sbin/data_update.sh &
sed "s/{MEM4}/$MEM4/g" /data/redis.conf >/tmp/redis.conf
ps
redis-server /tmp/redis.conf
