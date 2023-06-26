#!/bin/sh
ping whoami.03k.org -c1 -W 1 -w 1 -i 1 -4 > /dev/null
IPREX4='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'

echo =====PaoPaoDNS docker debug=====
echo "[info]" images build time : {bulidtime}
sleep 1
echo "[info]" ========== env info ==========
cat /tmp/env.conf
sleep 5
echo "[info]" ========== process info ==========
ps -ef
sleep 5
echo "[info]" ========== cn list info ==========
grep whoami /data/force_cn_list.txt
echo "[info]" ========== reids info ==========
redis-cli -s /tmp/redis.sock info | grep human
redis-cli -s /tmp/redis.sock dbsize
sleep 5
echo "[test]" IP test, you will see that all the following IPs are your public network exit IP !
echo "[test]" ========== IP TEST START ==========
echo CN IP URL:
curl -sk4 http://test.ipw.cn | grep -Eo "$IPREX4" | tail -1
curl -sk4 http://ipsu.03k.org | grep -Eo "$IPREX4" | tail -1
echo ------------------
echo Non-CN IP URL:
curl -sk4 https://www.cloudflare.com/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
curl -sk4 https://1.0.0.1/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
curl -sk4 https://1.1.1.1/cdn-cgi/trace | grep -Eo "$IPREX4" | tail -1
curl -sk4 http://checkip.synology.com/ | grep -Eo "$IPREX4" | tail -1
curl -sk4 https://v4.ident.me/ | grep -Eo "$IPREX4" | tail -1
echo ------------------
sleep 5
echo IP INFO:
curl -d "" http://ip.03k.org
echo
sleep 1
echo ------------------
echo ----mosdns whoami aka dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p53
echo ------------------
echo ----local-unbound whoami aka dig:
dig +short whoami.ds.akahelp.net @127.0.0.1 txt -p5301
echo ------------------
sleep 1
echo ----mosdns whoami 03k dig:
dig +short whoami.03k.org @127.0.0.1 a -p53
echo ------------------
echo ----local-unbound whoami 03k dig:
dig +short whoami.03k.org @127.0.0.1 a -p5301
echo "[test]" ========== IP TEST END ==========
echo
echo "[test]" The DNS hijacking test, you will see timed out message !
echo "[test]" ========== DNS HIJACK START ==========
nslookup www.qq.com 6.7.8.9
echo "[test]" ========== DNS HIJACK END ==========
sleep 1
echo "[test]" CN domain test, you will see that the DNS resolution result is CN IP !
echo "[test]" ========== CN DOMAIN TEST START ==========
echo ----mosdns CN dig:
dig +short www.taobao.com @127.0.0.1 -p53
echo ------------------
echo ----local-unbound CN dig:
dig +short www.taobao.com @127.0.0.1 -p5301
echo "[test]" ========== CN DOMAIN TEST END ==========
sleep 3
echo "[test]" Non-CN domain test, you will see that the DNS resolution result is correct IP !
echo "[test]" ========== Non-CN DOMAIN TEST START ==========
echo ----mosdns Non-CN dig:
dig +short www.youtube.com @127.0.0.1 -p53 | head -3
sleep 1
echo ------------------
echo ----dnscrypt-unbound NOCN dig:
dig +short www.youtube.com @127.0.0.1 -p5304 | head -3
sleep 1
echo ------------------
echo ----dnscrypt Non-CN dig:
dig +short www.youtube.com @127.0.0.1 -p5302 | head -3
sleep 1
echo ------------------
echo ----dnscrypt-socks5 Non-CN dig:
dig +short www.youtube.com @127.0.0.1 -p5303 | head -3
sleep 1
echo "[test]" ========== Non-CN DOMAIN TEST END ==========
sleep 3
echo "[test]" IPv6 Dual CN test: you will see that IPv6 is OK !
echo "[test]" ========== IPV6 CN DOMAIN TEST START ==========
dig +short www.taobao.com @127.0.0.1 aaaa -p53
dig +short www.qq.com @127.0.0.1 aaaa -p53
echo "[test]" ========== IPV6 CN DOMAIN TEST END ==========
echo "[test]" IPv6 Dual Non-CN test: you will see that IPv6 is empty !
echo "[test]" ========== IPV6 Non-CN DOMAIN TEST START ==========
dig +short www.youtube.com @127.0.0.1 aaaa -p53
echo "[test]" ========== IPV6 Non-CN DOMAIN TEST END ==========
echo "[test]" IPv6 only Non-CN test: you will see that IPv6 is ok !
echo "[test]" ========== IPV6 ONLY Non-CN DOMAIN TEST START ==========
dig +short www.youtube.com @127.0.0.1 aaaa -p53
dig +short ip6.03k.org @127.0.0.1 aaaa -p53
dig +short checkipv6.synology.com @127.0.0.1 aaaa -p53
echo "[test]" ========== IPV6 ONLY Non-CN DOMAIN TEST END ==========
echo
echo "[info]" ALL TEST FINISH.
