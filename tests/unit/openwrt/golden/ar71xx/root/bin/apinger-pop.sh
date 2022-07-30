#!/bin/sh

if [ -z ${1} ]; then
  echo "[ERROR] require arg for setting the gateway"
  exit 1
fi

sed "s/<DEFAULTGATEWAY>/${1}/g" /etc/apinger.tmpl > /tmp/apinger.conf
# Only restart apinger if compare has diff
if ! cmp /tmp/apinger.conf /etc/apinger.conf; then
  # Cant use "service" since thats a shell function
  sleep 5
  cp /tmp/apinger.conf /etc/apinger.conf && /etc/init.d/apinger restart
fi
