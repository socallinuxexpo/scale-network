#!/usr/bin/env python3
'''
CSV data source tests
'''
import datasource as ds


def test_aplist_csv():
    '''test aplist.csv'''
    meta = {
        "file": "./aps/aplist.csv",
        "header": True,
        "count": 10,
        "cols": [
            ds.isvalidhostname,
            ds.isuntested,
            ds.isvalidmac,
            ds.isvalidip,
            ds.isvalidwifi24chan,
            ds.isvalidwifi5chan,
            ds.isint,
            ds.isintorempty,
            ds.isintorempty,
            ds.isintorempty
        ]
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_pilist_csv():
    '''test pilist.csv'''
    meta = {
        "file": "./pi/pilist.csv",
        "header": True,
        "count": 2,
        "cols": [
            ds.isvalidhostname,
            ds.isvalidip
        ]
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_routerlist_csv():
    '''test routerlist.csv'''
    meta = {
        "file": "./routers/routerlist.csv",
        "header": True,
        "count": 2,
        "cols": [
            ds.isvalidhostname,
            ds.isvalidip
        ]
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_serverlist_csv():
    '''test serverlist.csv'''
    meta = {
        "file": "./servers/serverlist.csv",
        "header": True,
        "count": 5,
        "cols": [
            ds.isvalidhostname,
            ds.isvalidmac,
            ds.isvalidiporempty,
            ds.isvalidiporempty,
            ds.isuntested
        ]
    }
    result, err = ds.test_csvfile(meta)
    assert result, err


def test_switchtypes_tsv():
    '''test switchtypes'''
    meta = {
        "file": "../switch-configuration/config/switchtypes",
        "header": False,
        "count": 7,
        "cols": [
            ds.isvalidhostname,
            ds.isint,
            ds.isint,
            ds.isvalidip,
            ds.isvalidtype,
            ds.isvalidhierarchy,
            ds.isvalidnoiselevel
        ]
    }
    result, err = ds.test_tsvfile(meta)
    assert result, err
