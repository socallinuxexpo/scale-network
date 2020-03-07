#!/bin/bash
cat /etc/scale-release | grep -q 5aea29656267686220d9bfcc25dab9e5e457787b
if [ "$?" -eq "0" ];then
  if [ ! -f "/etc/resolv.conf" ]; then
    ln -sf /tmp/resolv.conf.d/resolv.conf.auto /etc/resolv.conf
    echo "Re-linked /etc/resolv.conf"
    ntpd -q -p 1.openwrt.pool.ntp.org
    echo "updated time"
  fi
else
  echo "[ERROR] This is not the right version, reflash!"
fi
