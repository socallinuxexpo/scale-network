#!/usr/bin/env python

# Dynamic inventory script used to slurp in various
# SCaLE specific text files to produce a sane inventory to ansible

import os
import re

# constants with locations to files or directories within the repo
vlansddir = "../switch-configuration/config/vlans.d/"
switchesfile = "../switch-configuration/config/switchtypes"
serverfile = "../facts/servers/serverlist.tsv"

# globals
#
# vlans = []{name, id, ipv6prefix, ipv6bitmask, ipv4prefix, ipv4bitmask,
# building, description}
vlans = []
# switches = []{name, ipv6address}
switches = []
# servers = []{name, mac-address, ipv6, ipv4, ansiblerole, vlanname}
servers = []
# inv = {
#    "group": {
#        "hosts": [
#            "192.168.28.71",
#            "192.168.28.72"
#        ],
#        "vars": {
#            "ansible_ssh_user": "johndoe",
#            "ansible_ssh_private_key_file": "~/.ssh/mykey",
#            "example_variable": "value"
#        }
#    },
#    "_meta": {
#        "hostvars": {
#            "192.168.28.71": {
#                "host_specific_var": "bar"
#            },
#            "192.168.28.72": {
#                "host_specific_var": "foo"
#            }
#        }
#    }
# }
inv = {
    "servers": {
        "hosts": [],
        "vars": {},
    },
    "switches": {
        "hosts": [],
    },
    "_meta": {
        "hostvars": {}
    }
}


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
                if ipv6[1] == "0":
                    ipv6 = [" ", " "]
                ipv4 = elems[3].split('/')
                if ipv4[1] == "0":
                    ipv4 = [" ", " "]
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
                vlan = ""
                for v in vlans:
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


# populateinv() will populate the master inventory dictionary
def populateinv():
    for s in switches:
        inv["switches"]["hosts"].append(s["name"])
        inv["_meta"]["hostvars"][s["name"]] = {
            "ipv6": s["ipv6"],
        }
    for s in servers:
        if s["ansiblerole"] not in inv.keys():
            inv[s["ansiblerole"]] = {
                "hosts": [],
                "vars": {},
            }
        inv["servers"]["hosts"].append(s["name"])
        inv[s["ansiblerole"]]["hosts"].append(s["name"])
        inv["_meta"]["hostvars"][s["name"]] = {
                "ansible_host": s["ipv4"],
                "ipv6": s["ipv6"],
                "ipv4": s["ipv4"],
                "macaddress": s["macaddress"],
                "vlan": s["vlan"],
                "fqdn": s["name"] + ".scale.lan",
        }


def main():
#    populatevlans()
    populateswitches()
    populateservers()
    populateinv()
    print(inv)


if __name__ == "__main__":
    main()
