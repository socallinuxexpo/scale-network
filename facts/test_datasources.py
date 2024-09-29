#!/usr/bin/env python3
"""
CSV data source tests
"""

import os
import datasource as ds


def test_apuse_csv():
    """test apuse.csv"""
    meta = {
        "file": "./aps/apuse.csv",
        "header": True,
        "count": 9,
        "cols": [
            ds.isvalidhostname,
            ds.isuntested,
            ds.isvalidip,
            ds.isvalidwifi24chan,
            ds.isvalidwifi5chan,
            ds.isint,
            ds.isintorempty,
            ds.isintorempty,
            ds.isintorempty,
        ],
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_aps_csv():
    """test aps.csv"""
    meta = {
        "file": "./aps/aps.csv",
        "header": True,
        "count": 2,
        "cols": [
            ds.isuntested,
            ds.isvalidmac,
        ],
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_pilist_csv():
    """test pilist.csv"""
    meta = {
        "file": "./pi/pilist.csv",
        "header": True,
        "count": 2,
        "cols": [ds.isvalidhostname, ds.isvalidip],
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_routerlist_csv():
    """test routerlist.csv"""
    meta = {
        "file": "./routers/routerlist.csv",
        "header": True,
        "count": 2,
        "cols": [ds.isvalidhostname, ds.isvalidip],
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_serverlist_csv():
    """test serverlist.csv"""
    meta = {
        "file": "./servers/serverlist.csv",
        "header": True,
        "count": 5,
        "cols": [
            ds.isvalidhostname,
            ds.isvalidmac,
            ds.isvalidiporempty,
            ds.isvalidiporempty,
            ds.isuntested,
        ],
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_switchtypes_tsv():
    """test switchtypes"""
    meta = {
        "file": "../switch-configuration/config/switchtypes",
        "header": False,
        "count": "9+",
        "cols": [
            ds.isvalidhostname,
            ds.isint,
            ds.isint,
            ds.isvalidip,
            ds.isvalidtype,
            ds.isvalidhierarchy,
            ds.isuntested,
            ds.isvalidmodel,
            ds.isvalidmac,
        ],
    }
    result, err = ds.test_tsvfile(meta)
    assert result, err

def test_switchconfigs_tsv():
    """test switchconfigs"""

    directory = "../switch-configuration/config/types/"
    for filename in os.listdir(directory):
        meta = {
            "file": directory + filename,
            "header": False,
            "count": "1+",
            "cols": [
                ds.isvalidport,
                ds.isuntested,
                ds.isuntested,
                ds.isuntested,
                ds.isvalidlink,
                ds.isuntested,
            ],
        }
        result, err = ds.test_tsvfile(meta)
        assert result, err

def test_vlansd_tsv():
    """test vlans.d/"""

    vlansddir = "../switch-configuration/config/vlans.d/"
    for filename in os.listdir(vlansddir):
        meta = {
            "file": vlansddir + filename,
            "header": False,
            "count": "6+",
            "cols": [
                ds.isuntested,
                ds.isuntested,
                ds.isuntested,
                ds.isvalidsubnet,
                ds.isvalidsubnet,
                ds.isuntested,
            ],
        }
        result, err = ds.test_tsvfile(meta)
        assert result, err
