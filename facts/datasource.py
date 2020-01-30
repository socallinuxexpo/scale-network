#!/usr/bin/env python3
'''
CSV validation library
'''
import ipaddress
import re


def isuntested(value):
    # pylint: disable=unused-argument
    ''' dummy function for untested values'''
    return True


def isvalidhostname(hostname):
    '''
    test for valid short hostname with letters, numbers, and dashes
    cannot begin or end with a dash
    '''
    pattern = r"^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$"
    result = re.match(pattern, hostname)
    if result:
        return True
    return False


def isvalidip(addr):
    '''test for valid v4 or v6 ip'''
    try:
        ipaddress.ip_address(addr)
    except ValueError:
        return False
    return True


def isvalidiporempty(val):
    '''test for valid ip or empty'''
    return isvalidip(val) or val == ''


def isvalidmac(macaddr):
    '''test for valid colon seperate mac address'''
    pattern = r"^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$"
    result = re.match(pattern, macaddr)
    if result:
        return True
    return False


def isvalidwifi24chan(chan):
    '''test for valid 2.4Ghz WiFi channel'''
    return int(chan) >= 1 and int(chan) <= 11


def isvalidwifi5chan(chan):
    '''
    test for valid 5Ghz WiFi channel
    allows DFS channels
    '''
    return ((int(chan) >= 36 and int(chan) <= 144) and int(chan) %2 == 0) or \
        ((int(chan) >= 149 and int(chan) <= 165) and int(chan) %2 == 1)


def isint(val):
    '''test for integer'''
    return val.isdigit()


def isintorempty(val):
    '''test for integer or empty'''
    return val.isdigit() or val == ''


def test_csvfile(meta):
    '''
    test a file using the supplied metadata
    structured as:
    {
        file: file's path
        header: True if top row is a header, skip field validation
        count: number of expected columns
        cols: [] a list of validations functions to be applied to the
                corresponding column index.
    }
    '''
    fha = open(meta["file"])
    lines = fha.readlines()
    fha.close()
    for linenum, line in enumerate(lines):
        elems = re.split(',', line)
        # check for expected number of columns
        if len(elems) != meta["count"]:
            return False, "invalid col count at line " + str(linenum)
        # skip validators for header row
        if meta["header"] and linenum == 0:
            continue
        # run the validators for each column
        for i, val in enumerate(elems):
            if not meta["cols"][i](val.rstrip('\n')):
                return False, "invalid field " + val + " at line " + str(linenum)
    return True, ""
