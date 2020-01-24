#!/usr/bin/env python3
'''
Tests for inventory.py
'''

import inventory

def test_makevlan():
    '''test cases for the makevlan() function'''
    cases = [
        ["VLAN\tcfCTF\t\t504\t2001:470:f325:504::/64\t10.128.4.0/24\tCapture the Flag", {
            "name": "cfCTF",
            "id": "504",
            "ipv6prefix": "2001:470:f325:504::",
            "ipv6bitmask": "64",
            "ipv4prefix": "10.128.4.0",
            "ipv4bitmask": "24",
            "building": "Conference",
            "description": "Capture the Flag",
            "ipv6dhcp1a": "2001:470:f325:504:1::1",
            "ipv6dhcp1b": "2001:470:f325:504:1::400",
            "ipv6dhcp2a": "2001:470:f325:504:2::1",
            "ipv6dhcp2b": "2001:470:f325:504:2::400",
            "ipv4dhcp1a": "10.128.4.80",
            "ipv4dhcp1b": "10.128.4.165",
            "ipv4dhcp2a": "10.128.4.166",
            "ipv4dhcp2b": "10.128.4.254",
            "ipv4router": "10.128.4.1",
            "ipv4netmask": "255.255.255.0",
            "ipv6dns1": "",
            "ipv6dns2": "",
            "ipv4dns1": "",
            "ipv4dns2": "",
        }],
        ["VLAN\tBadVLAN\t\tABC\t2001:470:f325:504::/64\t10.128.4.0/24\tBad VLAN", None],
    ]
    for line, vlan in cases:
        assert inventory.makevlan(line, "Conference") == vlan, line

def test_isvalidip():
    '''test cases for the isvalidip() function'''
    cases = [
        ["127.0.0.1", True],
        ["::1", True],
        ["10.1.1.1", True],
        ["2001:470:f325:107:8bfa:646e:811:241c", True],
        ["string", False],
        ["FFFF:VT40:f325:107:8bfa:646e:811:241c", False],
        ["256.0.0.1", False],
        ["2001:470:f325:107:8bfa:646e:811", False],
    ]
    for ipaddr, result in cases:
        assert inventory.isvalidip(ipaddr) == result, ipaddr
