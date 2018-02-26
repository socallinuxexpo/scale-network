#!/usr/bin/env python

# Dynamic inventory script used to slurp in various
# SCaLE specific text files to produce a sane inventory to ansible

import os
import re

# constants with locations to files or directories within the repo
vlansddir = "../switch-configuration/config/vlans.d/"
switchesfile = "../switch-configuration/config/switchtypes"
serverfile = "../facts/servers/serverlist.tsv"
apfile = "../facts/aps/aplist.tsv"
pifiles = "../facts/pi/pilist.tsv"

# globals
#
# vlans = []{name, id, ipv6prefix, ipv6bitmask, ipv4prefix, ipv4bitmask,
# building, description}
vlans = []
# switches = []{name, ipv6address}
switches = []
# servers = []{name, mac, ipv6, ipv4, role, vlanname, bldg, vlans}
servers = []
# apfile = []{name, power5g?, freq5g?, power2g?, freq2g?, mac, building}
aps = []
# pis = []{name, mac-address, building }
pis = []
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
                ipv6 = elems[3].split('/')
                if ipv6[1] == "0":
                    ipv6 = [" ", " "]
                ipv4 = elems[4].split('/')
                if ipv4[1] == "0":
                    ipv4 = [" ", " "]
                vlans.append({
                    "name": elems[1],
                    "id": elems[2],
                    "ipv6prefix": ipv6[0],
                    "ipv6bitmask": ipv6[1],
                    "ipv4prefix": ipv4[0],
                    "ipv4bitmask": ipv4[1],
                    "building": file,
                    "description": elems[5].split('\n')[0],
                })


# ip4toptr() generate a PTR
def ip4toptr(ipaddress):
    splitip = re.split(r'\.', ipaddress)
    return splitip[3] + "." + splitip[2] + "." + splitip[1]


# ip6toptr() generates a PTR
def ip6toptr(ipaddress):
    splitip = re.split(r'::', ipaddress)
    ptr = []
    for i in range(0, 32):
        ptr.append(0)
    ix = 0
    for c in splitip[1][::-1]:
        if not c == ":":
            ptr[ix] = c
            ix += 1
        else:
            while not ix % 4 == 0:
                ptr[ix] = 0
                ix += 1
    iy = 31
    for h in re.split(r':', splitip[0]):
        while len(h) < 4:
            h = "0" + str(h)
        for c in h:
            ptr[iy] = c
            iy -= 1

    retstr = ""
    for i in range(0, 32):
        retstr = retstr + str(ptr[i])
        if not i == 31:
            retstr = retstr + "."
    return retstr


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
                        building = v["building"]
                servers.append({
                    "name": elems[0],
                    "macaddress": elems[1],
                    "ipv6": ipv6,
                    "ipv4": elems[3],
                    "ansiblerole": elems[4].split('\n')[0],
                    "vlan": vlan,
                    "building": building,
                })


# populateinv() will populate the master inventory dictionary
def populateinv():
    for s in switches:
        inv["switches"]["hosts"].append(s["name"])
        inv["_meta"]["hostvars"][s["name"]] = {
            "ipv6": s["ipv6"],
            "ipv6ptr": ip6toptr(s["ipv6"]),
            "fqdn": s["name"] + ".scale.lan"
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
                "ipv6ptr": ip6toptr(s["ipv6"]),
                "ipv4": s["ipv4"],
                "ipv4ptr": ip4toptr(s["ipv4"]),
                "macaddress": s["macaddress"],
                "vlan": s["vlan"],
                "fqdn": s["name"] + ".scale.lan",
                "vlans": vlans,
                "building": s["building"],
        }


def main():

    populatevlans()
    populateswitches()
    populateservers()
    populateinv()
    print(inv)


if __name__ == "__main__":
    main()
