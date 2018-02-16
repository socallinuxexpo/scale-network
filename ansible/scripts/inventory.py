#!/usr/bin/env python

# Dynamic inventory script used to slurp in various 
# SCaLE specific text files to produce a sane inventory to ansible

# use of OOP, encapsulation, and non-standard libraries is purposly omitted to aide 
# in ease of support; "global" list variable are used with a dedicated function 
# for each 

import os
import re

# constants with locations to files or directories within the repo
vlansddir = "../../switch-configuration/config/vlans.d/"
switchesfile = "../../switch-configuration/config/switchtypes"
serverfile = "../../facts/servers/serverlist.tsv"

# globals
#
# vlans = []{name, id, ipv6prefix, ipv6bitmask, ipv4prefix, ipv4bitmask, building, description}
vlans = []
# switches = []{name, ipv6address}
switches = []
# servers = []{name, mac-address, ipv6, ipv4, ansiblerole, vlanname}
servers = []
# listinv = {group: {hosts: [], vars: {var1: x, var2: y}}}
listinv = {}
# hostinv = {host: {var1: x, var2: y}}
hostinv = {}

# populatevlans() will populate the vlans list
def populatevlans():
    filelist = (os.listdir(vlansddir))
    for file in filelist:
        f = open(vlansddir + file, 'r')
        flines = f.readlines()
        f.close()
        for line in flines:
            if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
                elems = re.split(r'\t+', line)
                ipv6 = elems[2].split('/')
                ipv4 = elems[3].split('/')
                vlans.append({
                    "name": elems[0],
                    "id": elems[1],
                    "ipv6prefix": ipv6[0],
                    "ipv6bitmask": ipv6[1],
                    "ipv4prefix": ipv4[0],
                    "ipv4bitmask": ipv4[1],
                    "building": file,
                    "description": elems[4].split('\n')[0],
                })

# populateswitches() will populate the switch list
def populateswitches():
    f = open(switchesfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            switches.append({
                "name": elems[0],
                "ipv6": elems[3],
            })

# populateservers() will populate the server list
def populateservers():
    f = open(serverfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            if len(elems) > 2:
                ipv6 = elems[2] 
                for v in vlans:
                    vlan = ""
                    if ipv6.find(v["ipv6prefix"]) > -1:
                        vlan = v["name"]
                    servers.append({
                    "name": elems[0],
                    "macaddress": elems[1],
                    "ipv6": ipv6,
                    "ipv4": elems[3],
                    "ansiblerole": elems[4].split('\n')[0],
                    "vlan": vlan,
                    })

def Main():
    populatevlans()
    print(vlans)
    populateswitches()
    print(switches)
    populateservers()
    print(servers)

if __name__ == "__main__":
    Main()
        