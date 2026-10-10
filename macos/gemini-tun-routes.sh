#!/bin/sh
# Keeps mihomo tun enabled and Google IP routes pointed at it.
# Self-heals after mihomo core restarts (e.g. Clash Verge profile switches).
SOCK="/var/run/clash-verge-service/users/501/verge-mihomo.sock"
DEV="utun1024"
V4="64.233.160.0/19 66.102.0.0/20 72.14.192.0/18 74.125.0.0/16 108.177.0.0/17 142.250.0.0/15 142.251.0.0/16 172.217.0.0/16 173.194.0.0/16 209.85.128.0/17 216.58.192.0/19 216.239.32.0/19 35.190.0.0/17 8.8.8.0/24 8.8.4.0/24"
V6="2001:4860::/32 2404:6800::/32 2607:f8b0::/32 2800:3f0::/32 2a00:1450::/32 2c0f:fb50::/32"

while :; do
  if [ -S "$SOCK" ] && curl -s --max-time 3 --unix-socket "$SOCK" http://localhost/version >/dev/null 2>&1; then
    cfg=$(curl -s --max-time 3 --unix-socket "$SOCK" http://localhost/configs | tr -d ' ')
    if ! echo "$cfg" | grep -q '"tun":{"enable":true'; then
      curl -s -X PATCH --max-time 3 --unix-socket "$SOCK" http://localhost/configs \
        -d '{"tun":{"enable":true,"device":"utun1024","stack":"system","auto-route":false,"auto-detect-interface":true,"dns-hijack":[],"mtu":1500}}' \
        -o /dev/null
    fi
    if ifconfig "$DEV" >/dev/null 2>&1; then
      for n in $V4; do /sbin/route -n add -inet -net "$n" -interface "$DEV" 2>/dev/null || true; done
      for n in $V6; do /sbin/route -n add -inet6 -net "$n" -interface "$DEV" 2>/dev/null || true; done
    fi
  fi
  sleep 30
done
