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
                name = elems[0]
                id = elems[1]
                ipv6 = elems[2].split('/')
                ipv6pre = ipv6[0]
                ipv6bm = ipv6[1]
                ipv4 = elems[3].split('/')
                ipv4pre = ipv4[0]
                ipv4bm = ipv4[1]
                build = file
                desc = elems[4].split('\n')[0]
                vlans.append({
                    "name": name,
                    "id": id,
                    "ipv6prefix": ipv6pre,
                    "ipv6bitmask": ipv6bm,
                    "ipv4prefix": ipv4pre,
                    "ipv4bitmask": ipv4bm,
                    "building": build,
                    "description": desc,
                })

def populateswitches():
    f = open(switchesfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            name = elems[0]
            ipv6 = elems[3]
            switches.append({
                "name": name,
                "ipv6": ipv6,
            })

def populateservers():
    f = open(serverfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            if len(elems) > 2:
                name = elems[0]            
                mac = elems[1]
                ipv6 = elems[2] 
                ipv4 = elems[3]
                for v in vlans:
                    if ipv6.find(v["ipv6prefix"]) > -1:
                        vlan = v["name"]
                ans = elems[4].split('\n')[0]
                servers.append({
                    "name": name,
                    "macaddress": mac,
                    "ipv6": ipv6,
                    "ipv4": ipv4,
                    "ansiblerole": ans,
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
        