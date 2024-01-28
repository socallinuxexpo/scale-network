#!/usr/bin/env python3
'''
CSV validation library
'''
import ipaddress
import re
from os import listdir
from os.path import isfile, join


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

def isvalidmodel(model):
    '''
    test for valid switch model (enumerated)
    '''
    return model in {
        "ex4200-48p", "ex4200-48t",
        "ex4200-24p", "ex4200-24t",
        "ex2200-48p", "ex2200-48t",
        "ex2200-24p", "ex2200-24t",
        "ex4200-48px"
    }

def isvalidip(addr):
    '''test for valid v4 or v6 ip'''
    try:
        ipaddress.ip_address(addr)
    except ValueError:
        return False
    return True

def isvalidsubnet(subnet):
    '''test for valid v4 or v6 subnet'''
    try:
        ipaddress.ip_network(subnet, strict=True)
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


def isvalidhierarchy(val):
    '''test for valid switch hierarchy'''
    pattern = r"^([A-Z]+[.][0-9])$"
    result = re.match(pattern, val)
    if result:
        return True
    return False

def isvalid_p_o_e(val):
    '''test for valid POE flag'''
    pattern = r"^(POE)|(-)$"
    result = re.match(pattern, val)
    if result:
        return True
    return False

def isvalidnoiselevel(val):
    '''test for valid noise level [Quiet, Normal, Loud]'''
    if val in ["Quiet", "Normal", "Loud", "??"]:
        return True
    return False


def isvalidtype(val):
    '''test for valid switch type, denoted by existence of file in types dir'''
    type_path = "../switch-configuration/config/types/"
    valid = [f for f in listdir(type_path) if isfile(join(type_path, f))]
    if val in valid:
        return True
    return False


def test_csvfile(meta):
    '''csv wrapper for test_datafile'''
    return test_datafile(r',', meta)


def test_tsvfile(meta):
    '''tsv wrapper for test_datafile'''
    return test_datafile(r'\t+', meta)


def test_datafile(delimiter, meta):
    '''
    test a file using the supplied delimiter and metadata
    structured as:
    {
        file: file's path
        header: True if top row is a header, skip field validation
        count: number of expected columns
        cols: [] a list of validations functions to be applied to the
                corresponding column index.
    }
    '''
    with open(meta["file"], encoding='utf-8') as fha:
        lines = fha.readlines()
    for linenum, line in enumerate(lines):
        # skip comments
        if line[0] == '/' and line[1] == '/':
            continue
        elems = re.split(delimiter, line)
        # check for expected number of columns
        #  OD -- Add ability to specify count >= n using "n+" syntax.
        if str(meta["count"])[-1] == "+":
            count = str(meta["count"])[:-1]
            if len(elems) < int(count):
                return False, "insufficient col count: " + str(len(elems)) + \
                  " wanted " + str(meta["count"]) + " at line " + str(linenum+1) \
                  + " of " + meta["file"]
        elif len(elems) != meta["count"]:
            return False, "invalid col count: " + str(len(elems)) + " wanted " + \
                str(meta["count"]) + " at line " + str(linenum+1) + " of " + meta["file"]
        # skip validators for header row
        if meta["header"] and linenum == 0:
            continue
        # run the validators for each column
        for i, val in enumerate(elems):
            if not meta["cols"][i](val.rstrip('\n')):
                return False, "invalid field " + val + " failed " + meta["cols"][i].__name__ + \
                " at line " + str(linenum+1) + " of " + meta["file"]
    return True, ""
