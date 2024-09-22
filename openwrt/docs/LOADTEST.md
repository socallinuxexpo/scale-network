# Load Test

This is fairly new but it has been done over the years to check stability of the
wifi drivers in particular. Its usefully to perform load tests after major openwrt
version updates and/or opkg changes.

## Server

Start the server on the openwrt AP:

```
iperf3 -s
```

> Note: If you want to run multiple clients you need to have them on separate ports

## Client

Run the `net_laodtest.sh` script, defaults should be fine but you can overwrite the IP
and the port number if need be:

```
bash openwrt/scripts/local/net_loadtest.sh
```

> NOTE: it will run continously and log to results-<DATE>.log
