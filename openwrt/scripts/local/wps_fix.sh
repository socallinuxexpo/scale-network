ssh root@$1 /bin/bash <<'ENDSSH'
cat /etc/scale-release | grep -q 5aea29656267686220d9bfcc25dab9e5e457787b
if [ "$?" -eq "0" ];then
  sed -i '6isleep 30 && echo 255 > /sys/devices/platform/reset-leds/leds/netgear:green:usb/brightness &' /etc/rc.local
else
  echo "This is not the right version, reflash!"
fi
ENDSSH
