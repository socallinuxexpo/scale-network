#!/usr/bin/env python3
'''
Tests for inventory.py
'''
import inventory


def test_getfilelineshdr():
    '''test cases for getfilelines() with header no building'''
    cases = [
        ["testdata/testaplist.csv", [
            "104-ap3,c6:04:15:90:57:c5,10.128.3.20,6,40,0,,,\n",
            "105-ap1,0a:bd:43:ac:5f:6c,10.128.3.21,11,44,0,4,1450,128\n"
        ]],
        ["testdata/testpilist.csv", [
            "pieb1d1c,2001:470:f325:107:efcf:2f67:f127:ba26\n"
        ]],
        ["testdata/testrouterlist.csv", [
            "br-mdf-01,2001:470:f325:103::2\n"
        ]],
        ["testdata/testserverlist.csv", [
            "server1,4c:72:b9:7c:41:17,2001:470:f325:503::5,10.128.3.5,core\n",
            "server2,4c:72:b9:7c:40:ec,,,"
        ]]
    ]
    for filename, lines in cases:
        assert inventory.getfilelines(filename, header=True) == lines, filename

def test_getfilelinesnobldg():
    '''test cases for getfilelines() no header no building'''
    cases = [
        ["testdata/testvlans", [
            "// Expo Center -- VLANS 100-499\n",
            "#include dir.d/testExpo\n",
            "\n",
            "// Conference Center -- VLANS 500-899\n",
            "#include dir.d/testConference\n",
            "\n"
        ]]
    ]
    for filename, lines in cases:
        assert inventory.getfilelines(filename) == lines, filename


def test_getfilelinesbldg():
    # pylint: disable=line-too-long
    '''test cases for the getfilelines() no header with building'''
    cases = [
        ["testConference", [
            "//\tConference\tCenter\t--\tVLANS\t500-899\n",
            "VLAN\tcfSCALE-SLOW	\t500\t2001:470:f325:500::/64\t10.128.128.0/21\t2.4G Wireless Network in Conference Center\n",
            "VLAN\tcfSigns\t\t\t507\t2001:470:f325:507::/64	0.0.0.0/0\tSigns network (Conference Center) IPv6 Only\n",
            "VLAN\tcfHam_N6S\t\t509\t2001:470:f325:509::/64\t10.128.9.0/24\tHAM radio station in Conference Center\n",
            "//510-599 not used\n"
        ]],
        ["testExpo", [
            "// Expo Center -- VLANS 100-499\n",
            "VLAN\texSCALE-SLOW\t\t100\t2001:470:f325:100::/64\t10.0.128.0/21\t2.4G Wireless Network in Expo Center\n",
            "//106 not used\n",
            "VLAN\texAkamai\t\t\t111\t2001:470:f325:111::/64\t0.0.0.0/0\tSpecial public Akamai Cache Cluster network (has IPv4 from convention center)\n",
            "//112 through 199 not used\n",
            "//200 through 499 Vendors\n",
            "//200-498 are dynamically generated from Booth information file as Vendor VLANs.\n",
            "//The difference is that these VLAN interfaces will also be built with firewall filters to prevent access to other\n",
            "//VLANs (vendor_vlan <-> internet only)\n",
            "VVRNG\tvendor_vlan_\t\t200-498\t2001:470:f325:200::/54\t10.2.0.0/15\tDynamically allocated and named booth VLANs\n",
            "//499 is reserved for the Vendor backbone VLAN between the Expo switches and the routers.\n",
        ]]
    ]
    for filename, caseslines in cases:
        filelines = inventory.getfilelines(filename, directory="./testdata/dir.d/", building="testbuilding")
        for i, line in enumerate(caseslines):
            assert filelines[i] == [line, "testbuilding"], line


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
