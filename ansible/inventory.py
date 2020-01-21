#!/usr/bin/env python3
'''
Dynamic inventory script used to slurp in various
SCaLE specific text files to produce a sane inventory to ansible
'''
import ipaddress
import json
import math
import re

SWCONFIGDIR = "../switch-configuration/config/"
VLANSFILE = "vlans"
ROUTERFILE = "../facts/routers/routerlist.csv"
SWITCHESFILE = "../switch-configuration/config/switchtypes"
SERVERFILE = "../facts/servers/serverlist.csv"
APFILE = "../facts/aps/aplist.csv"
PIFILE = "../facts/pi/pilist.csv"

def getfilelines(filename, header=False, directory="./", building=None):
    '''returns the contents of a file as lines
    omits the top line for git beautification if the header boolean is set to true
    takes optional directory flag to support parsing of vlans files
    takes optional building flag used for vlan parsing, otherwise is None'''
    fhandle = open(directory + filename, 'r')
    lines = fhandle.readlines()
    fhandle.close()
    if header:
        lines = lines[1:]
    if building is not None:
        newlines = []
        for line in lines:
            newlines.append([line, building])
        lines = newlines
    return lines


def makevlan(line, building):
    '''Makes a vlan dictionary from VLAN directive line'''
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
    vlanid = elems[2]
    if not vlanid.isdigit():
        return None
    return {
        "name": elems[1],
        "id": vlanid,
        "ipv6prefix": ipv6prefix,
        "ipv6bitmask": ipv6bitmask,
        "ipv4prefix": ipv4prefix,
        "ipv4bitmask": ipv4bitmask,
        "building": building,
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
    }


def genvlans(line, building):
    '''Makes a list of vlan dictionaries from a VVRNG directive'''
    vlans = []
    elems = re.split(r'\t+', line)
    rangeb, rangee = elems[2].split('-')
    for i in range(int(rangeb), int(rangee) + 1):
        ipv6prefix = elems[3].split('/')[0].split(rangeb + '::')[0] + str(i) + '::'
        ipv6dhcp = dhcp6ranges(ipv6prefix, 64)
        ocs = elems[4].split('.')
        ocs[1] = str(int(ocs[1]) + math.floor((i - int(rangeb)) / 256))
        ocs[2] = str(((i - int(rangeb)) % 256))
        ip4prefix = ocs[0] + "." + ocs[1] + "." + ocs[2] + ".0"
        ipv4dhcp = dhcp4ranges(ip4prefix, 24)
        ipv4netmask = bitmasktonetmask(24)
        vlans.append({
            "name": elems[1] + str(i),
            "id": i,
            "ipv6prefix": ipv6prefix,
            "ipv6bitmask": 64,
            "ipv4prefix": ip4prefix,
            "ipv4bitmask": 24,
            "building": building,
            "description": "Dyanmic vlan " + str(i),
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


def populatevlans():
    '''populate the vlan list'''
    vlans = []
    # seed root file
    todo = [["#include\tvlans", "vlan"]]
    while len(todo) > 0:
        current = todo[0]
        elems = re.split(r'^\t+|\s+', current[0])
        directive = elems[0]
        # we support 3 directives (#include, VLAN, VVRNG), everything else
        # is considered a comment and we silently drop it and continue
        if directive == "#include":
            filename = elems[1]
            building = re.split(r'/', filename)[-1] # the filename sans path is the building
            todo = todo + getfilelines(filename, directory=SWCONFIGDIR, building=building)
        elif directive == "VLAN":
            line = current[0]
            building = current[1]
            newvlan = makevlan(line, building)
            if newvlan is not None:
                vlans.append(newvlan)
        elif directive == "VVRNG":
            line = current[0]
            building = current[1]
            vlans = vlans + genvlans(line, building)
        todo.remove(current)
    return vlans


def isvalidip(addr):
    '''check an ipv4 or ipv6 address for validity'''
    try:
        ipaddress.ip_address(addr)
    except ValueError:
        return False
    return True


def ip4toptr(ip_address):
    '''generate a split PTR for IPv4 and return it'''
    splitip = re.split(r'\.', ipaddress.ip_address(ip_address).reverse_pointer)
    return splitip[1] + "." + splitip[2] + "." + splitip[3]


def ip6toptr(ip_address):
    '''generates a split PTR for IPv6 an returns it'''
    return re.split(r'\.ip6',
                    ipaddress.ip_address(ip_address).reverse_pointer)[0]


def dhcp6ranges(prefix, bitmask):
    '''generates start and end IPv6 addresses for 2x DHCP ranges'''
    if bitmask == 0:
        return ["", "", "", ""]
    prefsplit = re.split(r'\:\:', prefix)[0]
    return [
        prefsplit + ":1::1",
        prefsplit + ":1::400",
        prefsplit + ":2::1",
        prefsplit + ":2::400",
    ]


def dhcp4ranges(prefix, bitmask):
    '''generates start and end IPv4 addresses + router for 2x DHCP ranges'''
    if bitmask < 17 or bitmask > 24:
        return ["", "", "", "", ""]
    ipsplit = re.split(r'\.', prefix)
    if bitmask == 24:
        return [
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".80",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".165",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".166",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".254",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
        ]
    numocs = 2**(24 - bitmask)
    midthird = int(int(ipsplit[2]) + (numocs / 2))
    topthird = int(int(ipsplit[2]) + (numocs - 1))
    return [
        ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".80",
        ipsplit[0] + "." + ipsplit[1] + "." + str(midthird - 1) + ".255",
        ipsplit[0] + "." + ipsplit[1] + "." + str(midthird) + ".1",
        ipsplit[0] + "." + ipsplit[1] + "." + str(topthird) + ".254",
        ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
    ]


def bitmasktonetmask(bitmask):
    '''returns an IPv4 netmask given a bitmask'''
    if bitmask < 17 or bitmask > 24:
        return "255.255.255.255"
    return "255.255." + str(256 - 2**(24 - bitmask)) + ".0"


def populateswitches():
    '''populate the switch list'''
    switches = []
    fhandle = open(SWITCHESFILE, 'r')
    flines = fhandle.readlines()
    fhandle.close()
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


def populaterouters():
    '''populate the router list'''
    routers = []
    flines = getfilelines(ROUTERFILE, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if (line[0] == '/' or line[0] == '#' or line[0] == '\n'):
            continue
        elems = re.split(',', line)
        # Let's bail if we have an invalid number of columns
        if len(elems) < 2:
            continue
        ipaddr = elems[1].rstrip()
        # Let's bail if ip address is invalid
        if not isvalidip(ipaddr):
            continue
        routers.append({
            "name": elems[0],
            "ipv6": ipaddr,
        })
    return routers


def populateaps():
    '''populate the AP list'''
    aps = []
    flines = getfilelines(APFILE, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if (line[0] == '/' or line[0] == '#' or line[0] == '\n'):
            continue
        elems = re.split(',', line)
        # Lets bail if we have an invalid number of columns
        if len(elems) < 9:
            continue
        ipaddr = elems[2]
        # Lets bail if ip address is invalid
        if not isvalidip(ipaddr):
            continue
        aps.append({
            "name": elems[0],
            "mac": elems[1],
            "ipv4": ipaddr,
            "wifi2": elems[3],
            "wifi5": elems[4],
            "configver": elems[5].rstrip(),
        })
    return aps


def populatepis():
    '''populate the PI list'''
    pis = []
    flines = getfilelines(PIFILE, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if (line[0] == '/' or line[0] == '#' or line[0] == '\n'):
            continue
        elems = re.split(',', line)
        # Let's bail if we have an invalid number of columns
        if len(elems) < 2:
            continue
        ipaddr = elems[1].rstrip()
        # Let's bail we ip address is invalid
        if not isvalidip(ipaddr):
            continue
        pis.append({
            "name": elems[0],
            "ipv6": ipaddr,
        })
    return pis


def roomalias(name):
    '''generats room name based alias names for switches'''
    payload = []
    upname = name.upper()
    if "RM" in upname and '-' in name:
        comrooms = re.split("RM", upname)[1]
        comrooms = comrooms.replace('\n', '')
        rooms = re.split('-', comrooms)
        for room in rooms:
            payload.append(room)
    return payload


def populateservers(vlans):
    '''populate the server list'''
    servers = []
    flines = getfilelines(SERVERFILE, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if (line[0] == '/' or line[0] == '#' or line[0] == '\n'):
            continue
        elems = re.split(',', line)
        # let's bail if we have an invalid number of columns
        if len(elems) < 5:
            continue
        ipv6 = elems[2]
        ipv4 = elems[3]
        # let's bail if either ip is invalid, which also skips
        # unused server entries as well (where ip is blank)
        if not isvalidip(ipv6) or not isvalidip(ipv4):
            continue
        ansiblerole = elems[4].rstrip()
        vlan = ""
        for vln in vlans:
            if ipv6.find(vln["ipv6prefix"]) == 0:
                vlan = vln["name"]
                building = vln["building"]
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
            for i, _ in enumerate(vlans):
                vln = vlans[i]
                if building == vln["building"]:
                    vlans[i]["ipv6dns1"] = ipv6
                    vlans[i]["ipv4dns1"] = ipv4
                else:
                    vlans[i]["ipv6dns2"] = ipv6
                    vlans[i]["ipv4dns2"] = ipv4
    return servers


def populateinv(listlist):
    '''populates the final inventory which will become the command's output'''
    vlans = listlist[0]
    switches = listlist[1]
    servers = listlist[2]
    routers = listlist[3]
    aps = listlist[4]
    pis = listlist[5]
    ssh_args = "-o StrictHostKeyChecking=no -F /dev/null"
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
                "ansible_ssh_common_args": ssh_args,
                "ansible_python_interpreter": "/usr/bin/python3",
            }
        },
        "_meta": {
            "hostvars": {}
        }
    }
    for switch in switches:
        inv["switches"]["hosts"].append(switch["name"])
        inv["_meta"]["hostvars"][switch["name"]] = {
            "ipv6": switch["ipv6"],
            "ipv6ptr": ip6toptr(switch["ipv6"]),
            "fqdn": switch["name"] + ".scale.lan",
            "num": switch["num"],
            "aliases": switch["aliases"],
        }
    for apc in aps:
        inv["aps"]["hosts"].append(apc["name"])
        inv["_meta"]["hostvars"][apc["name"]] = {
            "mac": apc["mac"],
            "ipv4": apc["ipv4"],
            "ipv4ptr": ip4toptr(apc["ipv4"]),
            "ansible_host": apc["ipv4"],
            "wifi2": apc["wifi2"],
            "wifi5": apc["wifi5"],
            "configver": apc["configver"],
            "fqdn": apc["name"] + ".scale.lan",
        }
    for router in routers:
        inv["routers"]["hosts"].append(router["name"])
        inv["_meta"]["hostvars"][router["name"]] = {
            "ipv6": router["ipv6"],
            "ipv6ptr": ip6toptr(router["ipv6"]),
            "fqdn": router["name"] + ".scale.lan",
        }
    for pii in pis:
        inv["pis"]["hosts"].append(pii["name"])
        inv["_meta"]["hostvars"][pii["name"]] = {
            "ipv6": pii["ipv6"],
            "ipv6ptr": ip6toptr(pii["ipv6"]),
            "fqdn": pii["name"] + ".scale.lan",
        }
    for server in servers:
        if server["ansiblerole"] not in inv.keys():
            inv[server["ansiblerole"]] = {
                "hosts": [],
                "vars": {},
            }
        inv["servers"]["hosts"].append(server["name"])
        inv[server["ansiblerole"]]["hosts"].append(server["name"])
        inv["_meta"]["hostvars"][server["name"]] = {
            "ansible_host": server["ipv4"],
            "ipv6": server["ipv6"],
            "ipv6ptr": ip6toptr(server["ipv6"]),
            "ipv4": server["ipv4"],
            "ipv4ptr": ip4toptr(server["ipv4"]),
            "macaddress": server["macaddress"],
            "vlan": server["vlan"],
            "fqdn": server["name"] + ".scale.lan",
            "building": server["building"],
        }
    inv["all"]["vars"]["vlans"] = vlans
    return inv


def main():
    '''command entry point'''
    vlans = populatevlans()
    switches = populateswitches()
    servers = populateservers(vlans)
    routers = populaterouters()
    aps = populateaps()
    pis = populatepis()
    inv = populateinv([vlans, switches, servers, routers, aps, pis])
    print(json.dumps(inv))


if __name__ == "__main__":
    main()
