#!/usr/bin/env python3
# pylint: skip-file
"""
Dynamic inventory script used to slurp in various
SCaLE specific text files to produce a sane inventory to ansible
"""
import ipaddress
import json
import math
import os
import re
import sys
import jinja2

def getfilelines(filename, header=False, directory="./", building=None):
    """returns the contents of a file as lines
    omits the top line for git beautification if the header boolean is set to true
    takes optional directory flag to support parsing of vlans files
    takes optional building flag used for vlan parsing, otherwise is None"""
    fhandle = open(directory + filename, "r")
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
    """Makes a vlan dictionary from VLAN directive line"""
    elems = re.split(r"\t+", line)
    ipv6 = elems[3].split("/")
    ipv6prefix = ipv6[0]
    ipv6bitmask = ipv6[1]
    ipv6dhcp = dhcp6ranges(ipv6prefix, int(ipv6bitmask))
    ipv4 = elems[4].split("/")
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
        "ipv6dhcpStart": ipv6dhcp[0],
        "ipv6dhcpEnd": ipv6dhcp[1],
        "ipv4dhcpStart": ipv4dhcp[0],
        "ipv4dhcpEnd": ipv4dhcp[1],
        "ipv4router": ipv4dhcp[2],
        "ipv4netmask": ipv4netmask,
        "ipv6dns1": "",
        "ipv6dns2": "",
        "ipv4dns1": "",
        "ipv4dns2": "",
    }


def genvlans(line, building):
    """Makes a list of vlan dictionaries from a VVRNG directive"""
    vlans = []
    elems = re.split(r"\t+", line)
    rangeb, rangee = elems[2].split("-")
    for i in range(int(rangeb), int(rangee) + 1):
        ipv6prefix = elems[3].split("/")[0][:-1] + str(i) + "::"
        ipv6dhcp = dhcp6ranges(ipv6prefix, 64)
        ocs = elems[4].split(".")
        ocs[1] = str(int(ocs[1]) + math.floor((i - int(rangeb)) / 256))
        ocs[2] = str(((i - int(rangeb)) % 256))
        ip4prefix = ocs[0] + "." + ocs[1] + "." + ocs[2] + ".0"
        # Get dhcp ranges and router address
        ipv4dhcp = dhcp4ranges(ip4prefix, 24)
        ipv4netmask = bitmasktonetmask(24)
        vlans.append(
            {
                "name": elems[1] + str(i),
                "id": i,
                "ipv6prefix": ipv6prefix,
                "ipv6bitmask": 64,
                "ipv4prefix": ip4prefix,
                "ipv4bitmask": 24,
                "building": building,
                "description": "Dyanmic vlan " + str(i),
                "ipv6dhcpStart": ipv6dhcp[0],
                "ipv6dhcpEnd": ipv6dhcp[1],
                "ipv4dhcpStart": ipv4dhcp[0],
                "ipv4dhcpEnd": ipv4dhcp[1],
                "ipv4router": ipv4dhcp[2],
                "ipv4netmask": ipv4netmask,
                "ipv6dns1": "",
                "ipv6dns2": "",
                "ipv4dns1": "",
                "ipv4dns2": "",
            }
        )
    return vlans


def populatevlans(vlansdirectory, vlansfile):
    """populate the vlan list from a vlans diretory and file"""
    vlans = []
    # seed root file
    todo = [["#include\t" + vlansfile + "\tno_building"]]
    # This loop is pretty complex, should look into simplifying at some point
    while len(todo) > 0:
        current = todo[0]
        elems = re.split(r"^\t+|\s+", current[0])
        directive = elems[0]

        # We dont care about bridge vlan types since they wont require dhcp or dns
        if elems[1] == "vlans.d/Bridged":
            todo.remove(current)
            continue
        # we support 3 directives (#include, VLAN, VVRNG), everything else
        # is considered a comment and we silently drop it and continue
        if directive == "#include":
            filename = elems[1]
            building = re.split(r"/", filename)[
                -1
            ]  # the filename sans path is the building
            todo = todo + getfilelines(
                filename, directory=vlansdirectory, building=building
            )
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
    """check an ipv4 or ipv6 address for validity"""
    try:
        ipaddress.ip_address(addr)
    except ValueError:
        return False
    return True


def ip4toptr(ip_address):
    """generate a split PTR for IPv4 and return it"""
    return ipaddress.ip_address(ip_address).reverse_pointer


def ip6toptr(ip_address):
    """generates a split PTR for IPv6 an returns it"""
    return ipaddress.ip_address(ip_address).reverse_pointer


def dhcp6ranges(prefix, bitmask):
    """generates start and end IPv6 addresses for DHCP ranges"""
    if bitmask == 0:
        return ["", ""]
    prefsplit = re.split(r"\:\:", prefix)[0]
    # TODO: Infer this going forward
    # Conditional for the exVmVendor vlan, matching the ipv4 /20
    if prefix == "2001:470:f026:112::":
        return [
            prefsplit + ":d8c::1",
            prefsplit + ":d8c::1000", # 4096 addresses
        ]

    return [
        prefsplit + ":d8c::1",
        prefsplit + ":d8c::800", # 2048 addresses
    ]


def dhcp4ranges(prefix, bitmask):
    """generates start and end IPv4 addresses + router for DHCP ranges"""
    if bitmask < 17 or bitmask > 24:
        return ["", "", "", "", ""]
    ipsplit = re.split(r"\.", prefix)
    if bitmask == 24:
        # FIX: Hardcoding the hiInfra for larger pool to handle aplist.csv
        # not accounting for the 2 buildings since hilton is solo
        if prefix == "10.0.3.0":  # pylint: disable=R1705
            return [
                ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".150",
                ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".250",
                ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
            ]
        else:
            return [
                ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".80",
                ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".254",
                ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
            ]
    numocs = 2 ** (24 - bitmask)
    midthird = int(int(ipsplit[2]) + (numocs / 2))
    topthird = int(int(ipsplit[2]) + (numocs - 1))
    return [
        ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".80",
        ipsplit[0] + "." + ipsplit[1] + "." + str(topthird) + ".254",
        ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
    ]


def bitmasktonetmask(bitmask):
    """returns an IPv4 netmask given a bitmask"""
    if bitmask < 17 or bitmask > 24:
        return None
    return "255.255." + str(256 - 2 ** (24 - bitmask)) + ".0"


def populateswitches(switchesfile):
    """populate the switch list from a switches file"""
    switches = []
    fhandle = open(switchesfile, "r")
    flines = fhandle.readlines()
    fhandle.close()
    for line in flines:
        if not (line[0] == "/" or line[0] == " " or line[0] == "\n"):
            elems = re.split(r"\t+", line)
            name = elems[0]
            roomalias(name)
            switches.append(
                {
                    "name": name.lower(),
                    "num": elems[1],
                    "ipv6": elems[3],
                    "ipv6ptr": ip6toptr(elems[3]),
                    "fqdn": name.lower() + ".scale.lan",
                    "aliases": roomalias(name),
                }
            )
    return switches


def populaterouters(routersfile):
    """populate the router list"""
    routers = []
    flines = getfilelines(routersfile, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if line[0] == "/" or line[0] == "#" or line[0] == "\n":
            continue
        elems = re.split(",", line)
        # Let's bail if we have an invalid number of columns
        if len(elems) < 2:
            continue
        ipaddr = elems[1].rstrip()
        # Let's bail if ip address is invalid
        if not isvalidip(ipaddr):
            continue
        routers.append(
            {
                "name": elems[0].lower(),
                "ipv6": ipaddr,
                "ipv6ptr": ip6toptr(ipaddr),
                "fqdn": elems[0].lower() + ".scale.lan",
            }
        )
    return routers


def populateaps(apsfile, apusefile):
    """populate the AP list from an APs files"""
    apsdict = {}
    for row in getfilelines(apsfile, header=True):
        row = row.strip().split(",")
        apsdict[row[0]] = row[1:]

    apusedict = {}
    for row in getfilelines(apusefile, header=True):
        row = row.strip().split(",")
        # serial must be our primary key
        apusedict[row[1]] = [row[0]] + row[2:]

    result = {}
    for d in (apsdict, apusedict):
        for key, value in d.items():
            # merge two files based on serial primary key
            result.setdefault(key, []).extend(value)

    aps = []
    # Example of values in result
    # key: n8t-0054
    # values: c4:04:15:ad:a3:93,unknown-2,10.128.3.249,6,36,0,0,50,50
    for key, elems in result.items():
        try:
            ipaddr = elems[2]
        except IndexError:
            ipaddr = None

        # Lets bail if ip address is invalid
        if not isvalidip(ipaddr):
            continue
        aps.append(
            {
                "name": elems[1].lower(),
                "mac": elems[0],
                "ipv4": ipaddr,
                "ipv4ptr": ip4toptr(ipaddr),
                "wifi2": elems[3],
                "wifi5": elems[4],
                "configver": elems[5],
                "fqdn": elems[1].lower() + ".scale.lan",
                "aliases": [key],
            }
        )
    return aps


def populatepis(pisfile):
    """populate the PI list from a PIs file"""
    pis = []
    flines = getfilelines(pisfile, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if line[0] == "/" or line[0] == "#" or line[0] == "\n":
            continue
        elems = re.split(",", line)
        # Let's bail if we have an invalid number of columns
        if len(elems) < 2:
            continue
        ipaddr = elems[1].rstrip()
        # Let's bail we ip address is invalid
        if not isvalidip(ipaddr):
            continue
        pis.append(
            {
                "name": elems[0].lower(),
                "ipv6": ipaddr,
                "ipv6ptr": ip6toptr(ipaddr),
                "fqdn": elems[0].lower() + ".scale.lan",
            }
        )
    return pis

def serveralias(name):
    """generate aliases for servers"""
    payload = []
    match name.lower():
        case "monitoring1":
            payload = [
                "loghost",
                "monitoring",
            ]
        case "coreexpo":
            payload = [
                "coremaster",
                "ntpexpo",
            ]
        case "coreconf":
            payload = [
                "coreslave",
                "ntpconf",
            ]
    return payload


def roomalias(name):
    """generats room name based alias names for switches"""
    payload = []
    upname = name.upper()
    if "RM" in upname and "-" in name:
        comrooms = re.split("RM", upname)[1]
        comrooms = comrooms.replace("\n", "")
        rooms = re.split("-", comrooms)
        for room in rooms:
            payload.append(f'rm{room}')
    return payload


def populateservers(serversfile, vlans):
    """populate the server list from a servers file"""
    servers = []
    flines = getfilelines(serversfile, header=True)
    for line in flines:
        # Lets bail if this line is a comment
        if line[0] == "/" or line[0] == "#" or line[0] == "\n":
            continue
        elems = re.split(",", line)
        # let's bail if we have an invalid number of columns
        if len(elems) < 5:
            continue
        ipv6 = elems[2]
        ipv4 = elems[3]
        # let's bail if either ip is invalid, which also skips
        # unused server entries as well (where ip is blank)
        if not isvalidip(ipv6) or not isvalidip(ipv4):
            continue
        serverrole = elems[4].rstrip()
        vlan = ""
        for vln in vlans:
            if ipv6.find(vln["ipv6prefix"]) == 0:
                vlan = vln["name"]
                building = vln["building"]

        servers.append(
            {
                "name": elems[0],
                "macaddress": elems[1],
                "role": serverrole,
                "ipv6": ipv6,
                "ipv6ptr": ip6toptr(ipv6),
                "ipv4": ipv4,
                "ipv4ptr": ip4toptr(ipv4),
                "vlan": vlan,
                "fqdn": elems[0] + ".scale.lan",
                "building": building,
                "aliases": serveralias(elems[0]),
            }
        )
    return servers

def populatedhcpnameservers(servers, vlans):
    coreservers = [x for x in servers if x['role'] == 'core']
    for i, _ in enumerate(vlans):
        vlans[i]["ipv6dns1"] = coreservers[0]['ipv6']
        vlans[i]["ipv4dns1"] = coreservers[0]['ipv4']
        if len(coreservers) > 1:
            vlans[i]["ipv6dns2"] = coreservers[1]['ipv6']
            vlans[i]["ipv4dns2"] = coreservers[1]['ipv4']

def generatekeaconfig(servers, aps, vlans, outputdir):
    kea_config = {
        # DHCPv4 configuration starts on the next line
        "Dhcp4": {
            # First we set up global values
            # Set lifetime of lease to always be the same
            "valid-lifetime": 1440,
            "min-valid-lifetime": 1440,
            "max-valid-lifetime": 1440,
            # Next we set up the interfaces to be used by the server.
            "interfaces-config": {
                "interfaces": ["*"],
                "service-sockets-max-retries": 5,
                "service-sockets-retry-wait-time": 5000
            },
            # And we specify the type of lease database
            "lease-database": {
                "type": "memfile",
                "persist": True,
                "name": "/var/lib/kea/dhcp4.leases",
            },
            "option-data": [
            {
             "name": "domain-name-servers",
             "data": ','.join([x['ipv4'] for x in servers if x['role'] == 'core'])
            },
            {
             "name": "ntp-servers",
             "data": ','.join([x['ipv4'] for x in servers if x['role'] == 'core'])
            }
            ],
            "option-def": [
                {
                    "name": "radio24-channel",
                    "code": 224,
                    "type": "uint8",
                    "array": False,
                    "record-types": "",
                    "space": "dhcp4",
                    "encapsulate": "",
                },
                {
                    "name": "radio5-channel",
                    "code": 225,
                    "type": "uint8",
                    "array": False,
                    "record-types": "",
                    "space": "dhcp4",
                    "encapsulate": "",
                },
                {
                    "name": "ap-network-config",
                    "code": 226,
                    "type": "uint8",
                    "array": False,
                    "record-types": "",
                    "space": "dhcp4",
                    "encapsulate": "",
                },
            ],
            # All of our reservations are global
            # https://kea.readthedocs.io/en/kea-2.2.0/arm/dhcp4-srv.html#fine-tuning-dhcpv4-host-reservation
            "reservations-global": True,
            "reservations-in-subnet": True,
            "reservations": [],
            # Finally, we list the subnets from which we will be leasing addresses.
            "subnet4": []
            # DHCPv4 configuration ends with the next line
        }
      }
    keav6_config = {
        "Dhcp6": {
            # First we set up global values
            "valid-lifetime": 1440,
            "min-valid-lifetime": 1440,
            "max-valid-lifetime": 1440,
            # Next we set up the interfaces to be used by the server.
            "interfaces-config": {
                "interfaces": ["*"],
                "service-sockets-max-retries": 5,
                "service-sockets-retry-wait-time": 5000
            },
            # And we specify the type of lease database
            "lease-database": {
                "type": "memfile",
                "persist": True,
                "name": "/var/lib/kea/dhcp6.leases",
            },
            "option-data": [
            {
             # This option is different from dhcpv4
             # ref: https://kb.isc.org/docs/kea-configuration-for-small-office-or-home-use
             "name": "dns-servers",
             "data": ','.join([x['ipv6'] for x in servers if x['role'] == 'core'])
            },
            ],
            "option-def": [],
            "reservations-global": True,
            "reservations-in-subnet": False,
            "reservations": [],
            # Finally, we list the subnets from which we will be leasing addresses.
            "subnet6": []
        }
    }

    reservations_dict = [
        {
            "hostname": ap["name"],
            "hw-address": ap["mac"],
            "ip-address": ap["ipv4"],
            "option-data": [
                {"name": "radio24-channel", "data": ap["wifi2"]},
                {"name": "radio5-channel", "data": ap["wifi5"]},
                {"name": "ap-network-config", "data": ap["configver"]},
            ],
        }
        for ap in aps
    ]

    subnets_dict = []
    for vlan in vlans:
        # Make sure to skip vlans that have no ranges
        if vlan["ipv4bitmask"] == "0":
            continue
        else:
            subnet = {
                "subnet": vlan["ipv4prefix"] + "/" + str(vlan["ipv4bitmask"]),
                # generating uniq id (prefix with dots) for each subnet block to ensure autoids dont effect reordering
                # called out in: https://kea.readthedocs.io/en/latest/arm/dhcp4-srv.html#ipv4-subnet-identifier
                # subnet ids must be greater than zero and less than 4294967295
                "id": int(vlan["ipv4prefix"].replace('.', '')),
                "user-context": { "vlan": vlan["name"] },
                "pools": [{"pool": vlan["ipv4dhcpStart"] + " - " + vlan["ipv4dhcpEnd"]}],
                "option-data": [{ "name": "routers", "data": str(vlan["ipv4router"]) }],
            }
            # lower lease times for the APs
            if vlan["name"] in [ "cfInfra", "exInfra"]:
                # Set lifetime of lease to always be 300 seconds
                subnet["valid-lifetime"] = 300
                subnet["min-valid-lifetime"] = 300
                subnet["max-valid-lifetime"] = 300
            subnets_dict.append(subnet)

    kea_config["Dhcp4"]["subnet4"] = subnets_dict
    kea_config["Dhcp4"]["reservations"] = reservations_dict

    with open(f'{outputdir}/dhcp4-server.conf', 'w') as f:
        f.write(json.dumps(kea_config, indent=2))

    subnets6_dict = []
    for vlan in vlans:
        # Make sure to skip vlans that have no ranges
        if vlan["ipv6bitmask"] == "0":
            continue
        else:
            subnet = {
                "subnet": vlan["ipv6prefix"] + "/" + str(vlan["ipv6bitmask"]),
                # generating uniq id (prefix with dots) for each subnet block to ensure autoids dont effect reordering
                # called out in: https://kea.readthedocs.io/en/latest/arm/dhcp4-srv.html#ipv4-subnet-identifier
                # subnet ids must be greater than zero and less than 4294967295
                #
                # for ipv6 well take the last 4 hex digits to make sure the id is small enough but uniq
                "id": int(vlan["ipv6prefix"].replace(':', '')[-4:], 16),
                "user-context": { "vlan": vlan["name"] },
                "pools": [{"pool": vlan["ipv6dhcpStart"] + " - " + vlan["ipv6dhcpEnd"]}],
            }
            # lower lease times for the APs
            if vlan["name"] in ["cfInfra", "exInfra"]:
                # Set lifetime of lease to always be 300 seconds
                subnet["valid-lifetime"] = 300
                subnet["min-valid-lifetime"] = 300
                subnet["max-valid-lifetime"] = 300

            # TODO: This should probably be broken into its own config and dynamically included since each core
            # server will only be local per building. For now we are defaulting to exInfra
            if vlan["name"] in ["exInfra"]:
                # This is only required for the subnets that will allocate dhcpv6 addresses without a relay
                # in our case this is only ever the cf* vlan since thats where the VMs nic will be bridge to
                # TODO: we should figure out a better way of dynamically allocating this config of the
                # interface so is not hardcoded
                # https://kea.readthedocs.io/en/kea-2.2.0/arm/dhcp6-srv.html#ipv6-subnet-selection
                subnet["interface"] = "eth0"
            subnets6_dict.append(subnet)

    keav6_config["Dhcp6"]["subnet6"] = subnets6_dict

    with open(f'{outputdir}/dhcp6-server.conf', 'w') as f:
        f.write(json.dumps(keav6_config, indent=2))


def generatepromconfig(servers, aps, vlans, outputdir):
    prom_config = [
        {
            "targets": [ap["ipv4"] + ":9100"],
            "labels": {"ap": ap["name"]},
        }
        for ap in aps
    ]

    with open(f'{outputdir}/prom.json', 'w') as f:
        f.write(json.dumps(prom_config, indent=2))


def generatezones(switches,routers,pis,aps,servers, outputdir):
    content=''
    for batch in [switches, routers,pis,aps,servers]:
        zonetemplate = jinja2.Template('''
{% for item in batch -%}
{% if item['ipv6'] -%}
{{ item['name'] }}  IN  AAAA    {{ item['ipv6'] }}
{% endif -%}
{% if item['ipv4'] -%}
{{ item['name'] }}  IN  A    {{ item['ipv4'] }}
{% endif -%}
{% if item['num'] -%}
switch{{ item['num'] }}  IN  CNAME   {{item['fqdn'] }}.
{% endif -%}
{% for alias in item['aliases'] -%}
{{ alias }} IN    CNAME   {{ item['fqdn'] }}.
{% endfor -%}
{% endfor -%}
''')
        content += zonetemplate.render(
            batch=batch
        )
    with open(f'{outputdir}/db.scale.lan.records', "w") as f:
        f.write(content)
    # ipv4 and ipv6 ptr zones need to be in different zone files
    for ip in ['ipv4','ipv6']:
        content = ''
        for batch in [switches, routers,pis,aps,servers]:
            zonetemplate = jinja2.Template('''
{% for item in batch -%}
{%- set ptr = ip + 'ptr' -%}
{% if item[ptr] -%}
{{ item[ptr] }}.  IN  PTR    {{ item['fqdn'] }}.
{% endif -%}
{% endfor -%}
''')
            content += zonetemplate.render(
                batch=batch,
                ip=ip
            )
        with open(f'{outputdir}/db.{ip}.arpa.records', 'w') as f:
            f.write(content)

    return True

def main():
    """command entry point"""

    # Repository data files
    swconfigdir = "../switch-configuration/config/"
    vlansfile = "vlans"
    switchesfile = "../switch-configuration/config/switchtypes"
    serversfile = "../facts/servers/serverlist.csv"
    routersfile = "../facts/routers/routerlist.csv"
    apsfile = "../facts/aps/aps.csv"
    apusefile = "../facts/aps/apuse.csv"
    pisfile = "../facts/pi/pilist.csv"

    # populate the device type lists
    vlans = populatevlans(swconfigdir, vlansfile)
    switches = populateswitches(switchesfile)
    servers = populateservers(serversfile, vlans)
    routers = populaterouters(routersfile)
    aps = populateaps(apsfile, apusefile)
    pis = populatepis(pisfile)

    subcomm = sys.argv[1]
    outputdir = sys.argv[2]
    if not os.path.exists(outputdir):
        os.makedirs(outputdir)

    if subcomm == 'kea':
        generatekeaconfig(servers,aps,vlans,outputdir)
    elif subcomm == 'nsd':
        generatezones(switches,routers,pis,aps,servers,outputdir)
    elif subcomm == 'prom':
        generatepromconfig(servers,aps,vlans,outputdir)
    elif subcomm == 'all':
        generatekeaconfig(servers,aps,vlans,outputdir)
        generatezones(switches,routers,pis,aps,servers,outputdir)
        generatepromconfig(servers,aps,vlans,outputdir)


if __name__ == "__main__":
    main()
