#!/usr/bin/env python3

import ipaddress
import re
import sys


def mac2eui64(mac, prefix=None):
    """
    Convert a MAC address to a EUI64 address
    or, with prefix provided, a full IPv6 address
    """
    # http://tools.ietf.org/html/rfc4291#section-2.5.1
    eui64 = re.sub(r"[.:-]", "", mac).lower()
    eui64 = eui64[0:6] + "fffe" + eui64[6:]
    eui64 = hex(int(eui64[0:2], 16) ^ 2)[2:].zfill(2) + eui64[2:]

    if prefix is None:
        return ":".join(re.findall(r".{4}", eui64))
    else:
        try:
            net = ipaddress.ip_network(prefix, strict=False)
            euil = int("0x{0}".format(eui64), 16)
            return str(net[euil])
        except:  # noqa: E722
            return


if len(sys.argv) == 3:
    print(mac2eui64(mac=sys.argv[1], prefix=sys.argv[2]))
else:
    print(mac2eui64(mac=sys.argv[1]))
