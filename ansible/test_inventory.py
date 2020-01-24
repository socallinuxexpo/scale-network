#!/usr/bin/env python3
'''
Tests for inventory.py
'''

import inventory

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
