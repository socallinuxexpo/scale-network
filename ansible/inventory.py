#!/usr/bin/env python3

# Dynamic inventory script used to slurp in various
# SCaLE specific text files to produce a sane inventory to ansible

import ipaddress
import json
import os
import re

# constants with locations to files or directories within the repo
vlansddir = "../switch-configuration/config/vlans.d/"
routerfile = "../facts/routers/routerlist.tsv"
switchesfile = "../switch-configuration/config/switchtypes"
serverfile = "../facts/servers/serverlist.tsv"
apfile = "../facts/aps/aplist.tsv"
pifile = "../facts/pi/pilist.tsv"


# populatevlans() will populate the vlans list
def populatevlans():
    vlans = []
    filelist = (os.listdir(vlansddir))
    for file in filelist:
        f = open(vlansddir + file, 'r')
        flines = f.readlines()
        f.close()
        for line in flines:
            if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
                elems = re.split(r'\t+', line)
                ipv6 = elems[3].split('/')
                ipv6prefix = ipv6[0]
                ipv6bitmask = ipv6[1]
                ipv6dhcp = dhcp6ranges(ipv6prefix, int(ipv6bitmask))
                ipv4 = elems[4].split('/')
                ipv4prefix = ipv4[0]
                ipv4bitmask = ipv4[1]
                ipv4dhcp = dhcp4ranges(ipv4prefix, int(ipv4bitmask))
                ipv4netmask = bitmasktonetmask(int(ipv4bitmask))
                vlans.append({
                    "name": elems[1],
                    "id": elems[2],
                    "ipv6prefix": ipv6prefix,
                    "ipv6bitmask": ipv6bitmask,
                    "ipv4prefix": ipv4prefix,
                    "ipv4bitmask": ipv4bitmask,
                    "building": file,
                    "description": elems[5].rstrip(),
                    "ipv6dhcp1a": ipv6dhcp[0],
                    "ipv6dhcp1b": ipv6dhcp[1],
                    "ipv6dhcp2a": ipv6dhcp[2],
                    "ipv6dhcp2b": ipv6dhcp[3],
                    "ipv4dhcp1a": ipv4dhcp[0],
                    "ipv4dhcp1b": ipv4dhcp[1],
                    "ipv4dhcp2a": ipv4dhcp[2],
                    "ipv4dhcp2b": ipv4dhcp[3],
                    "ipv4router": ipv4dhcp[4],
                    "ipv4netmask": ipv4netmask,
                    "ipv6dns1": "",
                    "ipv6dns2": "",
                    "ipv4dns1": "",
                    "ipv4dns2": "",
                })
    return vlans


# ip4toptr() generate a split PTR and returns it
def ip4toptr(ip):
    splitip = re.split(r'\.', ipaddress.ip_address(ip).reverse_pointer)
    return splitip[1] + "." + splitip[2] + "." + splitip[3]


# ip6toptr() generates a split PTR and returns it
def ip6toptr(ip):
    return re.split(r'\.ip6', ipaddress.ip_address(ip).reverse_pointer)[0]


# dhcp6ranges() will return a list in [ipv6dhcp1a, ipv6dhcp1b, ipv6dhcp2a,...]
def dhcp6ranges(prefix, bitmask):
    if bitmask == 0:
        return ["", "", "", ""]
    prefsplit = re.split(r'\:\:', prefix)[0]
    return [
        prefsplit + ":1::1",
        prefsplit + ":0fff::fffe",
        prefsplit + ":f000::1",
        prefsplit + ":ffff::fffe",
    ]


# dhcp4ranges() will return a list in [ipv4dhcp1a, ipv4dhcp1b,... ipv4router]
def dhcp4ranges(prefix, bitmask):
    if bitmask < 17 or bitmask > 24:
        return ["", "", "", "", ""]
    ipsplit = re.split(r'\.', prefix)
    if bitmask == 24:
        return [
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".10",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".128",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".129",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".254",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
        ]
    numocs = 2**(24 - bitmask)
    midthird = int(int(ipsplit[2]) + (numocs / 2))
    topthird = int(int(ipsplit[2]) + (numocs - 1))
    return [
        ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".10",
        ipsplit[0] + "." + ipsplit[1] + "." + str(midthird - 1) + ".255",
        ipsplit[0] + "." + ipsplit[1] + "." + str(midthird) + ".1",
        ipsplit[0] + "." + ipsplit[1] + "." + str(topthird) + ".254",
        ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
    ]


# ipv4netmask() will return a netmask given a bitmask
def bitmasktonetmask(bitmask):
    if bitmask < 17 or bitmask > 24:
        return "255.255.255.255"
    else:
        return "255.255." + str(256 - 2**(24 - bitmask)) + ".0"


# populateswitches() will populate the switch list
def populateswitches():
    switches = []
    f = open(switchesfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            name = elems[0]
            roomalias(name)
            switches.append({
                "name": name,
                "num": elems[1],
                "ipv6": elems[3],
                "aliases": roomalias(name),
            })
    return switches


# populaterouters() will populate the router list
def populaterouters():
    routers = []
    f = open(routerfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not line[0] == '/' or line[0] == ' ' or line[0] == '\n':
            elems = re.split(r'\t+', line)
            routers.append({
                "name": elems[0],
                "ipv6": elems[1].rstrip(),
            })
    return routers


# populate aps() will populate the ap list
def populateaps():
    aps = []
    f = open(apfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            aps.append({
                "name": elems[0],
                "mac": elems[1],
                "ipv4": elems[2],
                "wifi2": elems[3],
                "wifi5": elems[4].rstrip(),
            })
    return aps


# populate pis() will populate the pi list
def populatepis():
    pis = []
    f = open(pifile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            pis.append({
                "name": elems[0],
                "ipv6": elems[1].rstrip(),
            })
    return pis


# swroomalias() will return a list of alias for multiple room use cases
def roomalias(name):
    payload = []
    upname = name.upper()
    if "RM" in upname and '-' in name:
        comrooms = re.split("RM", upname)[1]
        comrooms = comrooms.replace('\n', '')
        rooms = re.split('-', comrooms)
        for r in rooms:
            payload.append(r)
    return payload


# populateservers() will populate the server list
def populateservers(vlans):
    servers = []
    f = open(serverfile, 'r')
    flines = f.readlines()
    f.close()
    for line in flines:
        if not (line[0] == '/' or line[0] == ' ' or line[0] == '\n'):
            elems = re.split(r'\t+', line)
            if len(elems) > 2:
                ipv6 = elems[2]
                ipv4 = elems[3]
                ansiblerole = elems[4].rstrip()
                vlan = ""
                for v in vlans:
                    if ipv6.find(v["ipv6prefix"]) > -1:
                        vlan = v["name"]
                        building = v["building"]
                servers.append({
                    "name": elems[0],
                    "macaddress": elems[1],
                    "ipv6": ipv6,
                    "ipv4": ipv4,
                    "ansiblerole": ansiblerole,
                    "vlan": vlan,
                    "building": building,
                })
                if ansiblerole == "core":
                    for i in range(0, len(vlans)):
                        v = vlans[i]
                        if building == v["building"]:
                            vlans[i]["ipv6dns1"] = ipv6
                            vlans[i]["ipv4dns1"] = ipv4
                        else:
                            vlans[i]["ipv6dns2"] = ipv6
                            vlans[i]["ipv4dns2"] = ipv4
    return servers


# populateinv() will populate the master inventory dictionary
def populateinv(vlans, switches, servers, routers, aps, pis):
    # keep things simple, avoid existing ssh config and known_hosts issues
    sshArgs = "-o StrictHostKeyChecking=no -F /dev/null"
    inv = {
        "routers": {
            "hosts": [],
            "vars": {},
        },
        "servers": {
            "hosts": [],
            "vars": {},
        },
        "switches": {
            "hosts": [],
        },
        "aps": {
            "hosts": [],
        },
        "pis": {
            "hosts": [],
        },
        "all": {
            "vars": {
                "ansible_ssh_common_args": sshArgs,
            }
        },
        "_meta": {
            "hostvars": {}
        }
    }
    for s in switches:
        inv["switches"]["hosts"].append(s["name"])
        inv["_meta"]["hostvars"][s["name"]] = {
            "ipv6": s["ipv6"],
            "ipv6ptr": ip6toptr(s["ipv6"]),
            "fqdn": s["name"] + ".scale.lan",
            "num": s["num"],
            "aliases": s["aliases"],
        }
    for a in aps:
        inv["aps"]["hosts"].append(a["name"])
        inv["_meta"]["hostvars"][a["name"]] = {
            "mac": a["mac"],
            "ipv4": a["ipv4"],
            "ipv4ptr": ip4toptr(a["ipv4"]),
            "ansible_host": a["ipv4"],
            "wifi2": a["wifi2"],
            "wifi5": a["wifi5"],
            "fqdn": a["name"] + ".scale.lan",
        }
    for r in routers:
        inv["routers"]["hosts"].append(r["name"])
        inv["_meta"]["hostvars"][r["name"]] = {
            "ipv6": r["ipv6"],
            "ipv6ptr": ip6toptr(r["ipv6"]),
            "fqdn": r["name"] + ".scale.lan",
        }
    for p in pis:
        inv["pis"]["hosts"].append(p["name"])
        inv["_meta"]["hostvars"][p["name"]] = {
            "ipv6": p["ipv6"],
            "ipv6ptr": ip6toptr(p["ipv6"]),
            "fqdn": p["name"] + ".scale.lan",
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
                "building": s["building"],
        }
    inv["all"]["vars"]["vlans"] = vlans
    return inv


def main():
    vlans = populatevlans()
    switches = populateswitches()
    servers = populateservers(vlans)
    routers = populaterouters()
    aps = populateaps()
    pis = populatepis()
    inv = populateinv(vlans, switches, servers, routers, aps, pis)
    print(json.dumps(inv))


if __name__ == "__main__":
    main()
