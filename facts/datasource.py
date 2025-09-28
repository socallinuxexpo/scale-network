#!/usr/bin/env python3
"""
CSV validation library
"""

import ipaddress
import re
from os import listdir
from os.path import isfile, join


def isuntested(value):
    # pylint: disable=unused-argument
    """dummy function for untested values"""
    return True


def isvalidhostname(hostname):
    """
    test for valid short hostname with letters, numbers, and dashes
    cannot begin or end with a dash
    """
    pattern = r"^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])$"
    result = re.match(pattern, hostname)
    if result:
        return True
    return False


def is_valid_asset_id(asset_id):
    """
    test for valid asset ID, which has the same constraints as a hostname
    """
    return isvalidhostname(asset_id)


def isvalidmodel(model):
    """
    test for valid switch model (enumerated)
    """
    return model in {
        "ex4200-48p",
        "ex4200-48t",
        "ex4200-24p",
        "ex4200-24t",
        "ex2200-48p",
        "ex2200-48t",
        "ex2200-24p",
        "ex2200-24t",
        "ex4200-48px",
    }


def isvalidip(addr):
    """test for valid v4 or v6 ip"""
    try:
        ipaddress.ip_address(addr)
    except ValueError:
        return False
    return True


def is_valid_v6_suffix(suffix):
    """
    test for valid v6 suffix
    """
    pattern = r"^[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4})*$"

    if not re.match(pattern, suffix):
        return False

    groups = suffix.split(":")
    return all(group and len(group) <= 4 for group in groups)


def isvalidsubnet(subnet):
    """test for valid v4 or v6 subnet"""
    try:
        ipaddress.ip_network(subnet, strict=True)
    except ValueError:
        return False
    return True


def isvalidiporempty(val):
    """test for valid ip or empty"""
    return isvalidip(val) or val == ""


def isvalidmac(macaddr):
    """test for valid colon seperate mac address"""
    pattern = r"^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$"
    result = re.match(pattern, macaddr)
    if result:
        return True
    return False


def isvalidwifi24chan(chan):
    """test for valid 2.4Ghz WiFi channel"""
    return isint(chan) and int(chan) in {1, 6, 11}


def isvalidwifi5chan(chan):
    """
    test for valid 5Ghz WiFi channel
    allows DFS channels
    """
    return isint(chan) and int(chan) in {
        32,
        36,
        40,
        44,
        48,
        52,
        56,
        60,
        64,
        100,
        104,
        108,
        112,
        116,
        120,
        124,
        128,
        132,
        136,
        140,
        144,
        149,
        153,
        157,
        161,
        165,
        169,
        173,
        177,
    }


def is_valid_pi_vlan(vlan):
    """test for valid PI vlan"""
    # we currently constrain PI use to 3 existing vlans
    # this can be extended later as needed
    return isint(vlan) and int(vlan) in {
        107,
        110,
        507,
    }


def isint(val):
    """test for integer"""
    return val.isdigit()


def isintorempty(val):
    """test for integer or empty"""
    return val.isdigit() or val == ""


def isvalidhierarchy(val):
    """test for valid switch hierarchy"""
    pattern = r"^([A-Z]+[.][0-9])$"
    result = re.match(pattern, val)
    if result:
        return True
    return False


def isvalid_p_o_e(val):
    """test for valid POE flag"""
    pattern = r"^(POE)|(-)$"
    result = re.match(pattern, val)
    if result:
        return True
    return False


def isvalidnoiselevel(val):
    """test for valid noise level [Quiet, Normal, Loud]"""
    if val in ["Quiet", "Normal", "Loud", "??"]:
        return True
    return False


def isinaplist(val):
    """test for existence of the value in apuse.csv"""
    lines = []
    with open("aps/aps.csv", "r", encoding="utf-8") as fh:
        lines = fh.readlines()
    aplist = set()
    for line in lines[1:]:
        cols = line.split(",")
        aplist.add(cols[0])
    return val in aplist


def isvalidtype(val):
    """test for valid switch type, denoted by existence of file in types dir"""
    type_path = "../switch-configuration/config/types/"
    valid = [f for f in listdir(type_path) if isfile(join(type_path, f))]
    if val in valid:
        return True
    return False


def test_csvfile(meta):
    """csv wrapper for test_datafile"""
    return test_datafile(r",", meta)


def test_tsvfile(meta):
    """tsv wrapper for test_datafile"""
    return test_datafile(r"\t+", meta)


def test_datafile(delimiter, meta):
    """
    test a file using the supplied delimiter and metadata
    structured as:
    {
        file: file's path
        header: True if top row is a header, skip field validation
        count: number of expected columns
        cols: [] a list of validations functions to be applied to the
                corresponding column index.
    }
    """
    with open(meta["file"], encoding="utf-8") as fha:
        lines = fha.readlines()
    for linenum, line in enumerate(lines):
        # skip comments or empty lines
        if (line[0] == "/" and line[1] == "/") or (line.startswith("\n")):
            continue
        elems = re.split(delimiter, line)
        # check for expected number of columns
        #  OD -- Add ability to specify count >= n using "n+" syntax.
        if str(meta["count"])[-1] == "+":
            count = str(meta["count"])[:-1]
            if len(elems) < int(count):
                return False, "insufficient col count: " + str(
                    len(elems)
                ) + " wanted " + str(meta["count"]) + " at line " + str(
                    linenum + 1
                ) + " of " + meta["file"]
        elif len(elems) != meta["count"]:
            return False, "invalid col count: " + str(len(elems)) + " wanted " + str(
                meta["count"]
            ) + " at line " + str(linenum + 1) + " of " + meta["file"]
        # skip validators for header row
        if meta["header"] and linenum == 0:
            continue
        # run the validators for each column
        for i, val in enumerate(elems):
            # If we don't have tests for extra columns, ignore them.
            if i >= len(meta["cols"]):
                continue
            print("Processing index ", i, ' with value "', val, '"\n')
            if not meta["cols"][i](val.rstrip("\n")):
                print("Test failed at", i, "Because not newline?\n")
                return False, "invalid field " + val + " failed " + meta["cols"][
                    i
                ].__name__ + " at line " + str(linenum + 1) + " of " + meta["file"]
    return True, ""
