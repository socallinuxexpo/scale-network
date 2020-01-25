#!/usr/bin/env python3
'''
Tests for inventory.py
'''
import inventory


def test_getfilelines():
    '''test cases for the getfilelines() function'''
    # STUB


def test_dhcp6ranges():
    '''test cases for the dhcp6ranges() function'''
    cases = [
        [["2001:470:f325:504::", 64], [
            "2001:470:f325:504:1::1",
            "2001:470:f325:504:1::400",
            "2001:470:f325:504:2::1",
            "2001:470:f325:504:2::400",
        ]],
        [["2001:470:f325:111::", 64], [
            "2001:470:f325:111:1::1",
            "2001:470:f325:111:1::400",
            "2001:470:f325:111:2::1",
            "2001:470:f325:111:2::400"
        ]],
        [["::", 0], ["", "", "", ""]]
    ]
    for case, ranges in cases:
        prefix, bitmask = case
        assert inventory.dhcp6ranges(prefix, bitmask) == ranges, prefix + "/" + str(bitmask)


def test_dhcp4ranges():
    '''test cases for the dhcp4ranges() function'''
    cases = [
        [["10.0.136.0", 21], [
            "10.0.136.80",
            "10.0.139.255",
            "10.0.140.1",
            "10.0.143.254",
            "10.0.136.1"
        ]],
        [["10.0.2.0", 24], [
            "10.0.2.80",
            "10.0.2.165",
            "10.0.2.166",
            "10.0.2.254",
            "10.0.2.1"
        ]],
        [["0.0.0.0", 0], ["", "", "", "", ""]],
        [["38.98.46.128", 25], ["", "", "", "", ""]],
    ]
    for case, ranges in cases:
        prefix, bitmask = case
        assert inventory.dhcp4ranges(prefix, bitmask) == ranges, prefix + "/" + str(bitmask)


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


def test_bitmasktonetmask():
    '''test cases for the bitmasktonetmask() function'''
    cases = [
        [16, None],
        [17, "255.255.128.0"],
        [18, "255.255.192.0"],
        [19, "255.255.224.0"],
        [20, "255.255.240.0"],
        [21, "255.255.248.0"],
        [22, "255.255.252.0"],
        [23, "255.255.254.0"],
        [24, "255.255.255.0"],
        [25, None]
    ]
    for bitmask, netmask in cases:
        assert inventory.bitmasktonetmask(bitmask) == netmask, bitmask


def test_genvlans():
    '''test cases for the genvlans() function'''
    cases = [
        ["VVRNG\ttest_vlan_\t\t200-201\t2001:470:f325:200::/54\t10.2.0.0/15\tdynamic vlan", [
            {
                "name": "test_vlan_200",
                "id": 200,
                "ipv6prefix": "2001:470:f325:200::",
                "ipv6bitmask": 64,
                "ipv4prefix": "10.2.0.0",
                "ipv4bitmask": 24,
                "building": "Expo",
                "description": "Dyanmic vlan 200",
                "ipv6dhcp1a": "2001:470:f325:200:1::1",
                "ipv6dhcp1b": "2001:470:f325:200:1::400",
                "ipv6dhcp2a": "2001:470:f325:200:2::1",
                "ipv6dhcp2b": "2001:470:f325:200:2::400",
                "ipv4dhcp1a": "10.2.0.80",
                "ipv4dhcp1b": "10.2.0.165",
                "ipv4dhcp2a": "10.2.0.166",
                "ipv4dhcp2b": "10.2.0.254",
                "ipv4router": "10.2.0.1",
                "ipv4netmask": "255.255.255.0",
                "ipv6dns1": "",
                "ipv6dns2": "",
                "ipv4dns1": "",
                "ipv4dns2": ""
            },
            {
                "name": "test_vlan_201",
                "id": 201,
                "ipv6prefix": "2001:470:f325:201::",
                "ipv6bitmask": 64,
                "ipv4prefix": "10.2.1.0",
                "ipv4bitmask": 24,
                "building": "Expo",
                "description": "Dyanmic vlan 201",
                "ipv6dhcp1a": "2001:470:f325:201:1::1",
                "ipv6dhcp1b": "2001:470:f325:201:1::400",
                "ipv6dhcp2a": "2001:470:f325:201:2::1",
                "ipv6dhcp2b": "2001:470:f325:201:2::400",
                "ipv4dhcp1a": "10.2.1.80",
                "ipv4dhcp1b": "10.2.1.165",
                "ipv4dhcp2a": "10.2.1.166",
                "ipv4dhcp2b": "10.2.1.254",
                "ipv4router": "10.2.1.1",
                "ipv4netmask": "255.255.255.0",
                "ipv6dns1": "",
                "ipv6dns2": "",
                "ipv4dns1": "",
                "ipv4dns2": ""
            },
            ]
        ]
    ]
    for line, vlans in cases:
        assert inventory.genvlans(line, "Expo") == vlans, line


def test_ip4toptr():
    '''test cases for the ip4toptr() function'''
    cases = [
        ["10.128.3.5", "3.128.10"],
        ["10.0.3.200", "3.0.10"]
    ]
    for ipaddr, ptr in cases:
        assert inventory.ip4toptr(ipaddr) == ptr, ipaddr


def test_ip6toptr():
    '''test cases for the ip6toptr() function'''
    cases = [
        ["2001:470:f325:103::200:4",
         "4.0.0.0.0.0.2.0.0.0.0.0.0.0.0.0.3.0.1.0.5.2.3.f.0.7.4.0.1.0.0.2"],
        ["2001:470:f325:107:ad84:2d06:1dfe:7f67",
         "7.6.f.7.e.f.d.1.6.0.d.2.4.8.d.a.7.0.1.0.5.2.3.f.0.7.4.0.1.0.0.2"],
    ]
    for ipaddr, ptr in cases:
        assert inventory.ip6toptr(ipaddr) == ptr, ipaddr


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


def test_roomalias():
    '''test cases for the roomalias() function'''
    cases = [
        ["Rm101-102", ["101", "102"]],
        ["BallroomC", []]
    ]
    for name, aliases in cases:
        assert inventory.roomalias(name) == aliases, name


def test_populatevlans():
    '''test cases for the populatevlans() function'''
    # STUB


def test_populateswitches():
    '''test cases for the populateswitches() function'''
    # STUB


def test_populaterouters():
    '''test cases for the populaterouters() function'''
    # STUB


def test_populateaps():
    '''test cases for the populateaps() function'''
    # STUB


def test_populatepis():
    '''test cases for the populatepis() function'''
    # STUB


def test_populateservers():
    '''test cases for the populateservers() function'''
    # STUB
