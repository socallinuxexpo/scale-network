
iwinfo phy0 scan |while read line; do echo "$HOSTNAME,2.4g: $line"; done
iwinfo phy1 scan |while read line; do echo "$HOSTNAME,5g: $line"; done

