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
import pandas


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


def make_vlan(vlan_config):
    """
    Makes a vlan dictionary from a VLAN config:
    {
        'id': 105,
        'name': 'hiAV',
        'v6cidr': '2001:470:f026:105::/64',
        'v4cidr': '10.0.5.0/24',
        'description': 'Audio Visual Network (DHCP Helper to AV server)',
        'building': 'Conference',
    }
    """
    ipv6 = vlan_config["v6cidr"].split("/")
    ipv6prefix = ipv6[0]
    ipv6bitmask = ipv6[1]
    ipv6dhcp = dhcp6ranges(ipv6prefix, int(ipv6bitmask))
    ipv4 = vlan_config["v4cidr"].split("/")
    ipv4prefix = ipv4[0]
    ipv4bitmask = ipv4[1]
    ipv4dhcp = dhcp4ranges(ipv4prefix, int(ipv4bitmask))
    ipv4netmask = bitmasktonetmask(int(ipv4bitmask))
    vlanid = vlan_config["id"]
    if not vlanid.isdigit():
        return None
    return {
        "name": vlan_config["name"],
        "id": vlanid,
        "ipv6prefix": ipv6prefix,
        "ipv6bitmask": ipv6bitmask,
        "ipv4prefix": ipv4prefix,
        "ipv4bitmask": ipv4bitmask,
        "building": vlan_config["building"],
        "description": vlan_config["description"].rstrip(),
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


def gen_vlans(vlan_range, nameprefix, v6cidr, v4cidr, building):
    vlans = []
    rangeb, rangee = vlan_range.split("-")
    v6net = ipaddress.ip_network(v6cidr)
    v4octets = v4cidr.split("/")[0].split(".")

    for i in range(int(rangeb), int(rangee) + 1):
        # we prefix v6 /64s with the base + decimal value of the vlan
        # even though this doesn't match the hex value, easier for eyes
        v6base = str(v6net.network_address).rstrip(":")
        v6prefix = f"{v6base}:{i}::"

        # we prefix v4 /24s as an offset of the base
        offset = i - int(rangeb)
        octet1 = v4octets[0]
        octet2 = str(int(v4octets[1]) + math.floor(offset / 256))
        octet3 = str(offset % 256)
        v4prefix = f"{octet1}.{octet2}.{octet3}.0"

        vlan_config = {
            "id": str(i),
            "name": f"{nameprefix}{str(i)}",
            "v6cidr": f"{v6prefix}/64",
            "v4cidr": f"{v4prefix}/24",
            "description": f"Dynamic vlan {i}",
            "building": building,
        }
        new_vlan = make_vlan(vlan_config)
        if new_vlan is not None:
            vlans.append(new_vlan)

    return vlans


def load_vlan_file(vlansdirectory, filename, building=None, seen=None):
    """
    Recursively load a vlans file and all its includes into a DataFrame.
    """
    if seen is None:
        seen = set()

    # Prevent infinite loops
    if filename in seen:
        return pandas.DataFrame()
    seen.add(filename)

    # Derive building from filename (last path component)
    if building is None:
        building = filename.split("/")[-1]

    # Skip Bridged entirely
    if building == "Bridged":
        return pandas.DataFrame()

    filepath = vlansdirectory + filename

    with open(filepath, "r") as f:
        lines = f.readlines()

    rows = []
    child_dfs = []

    for line in lines:
        # Use the SAME regex as original code
        parts = re.split(r"^\t+|\s+", line)

        # Filter out empty strings from split
        parts = [p for p in parts if p]

        if not parts:
            continue

        directive = parts[0]

        # Skip comments
        if directive.startswith("//"):
            continue

        if directive == "#include":
            include_file = parts[1]
            child_building = include_file.split("/")[-1]
            child_df = load_vlan_file(
                vlansdirectory, include_file, child_building, seen
            )
            child_dfs.append(child_df)

        elif directive == "VLAN":
            # For VLAN/VVRNG, we need to re-split on tabs only to get proper columns
            # because the original makevlan/genvlans use tab splitting
            tab_parts = re.split(r"\t+", line)
            if len(tab_parts) >= 6:
                rows.append(
                    {
                        "directive": "VLAN",
                        "name": tab_parts[1],
                        "id": tab_parts[2],
                        "v6cidr": tab_parts[3],
                        "v4cidr": tab_parts[4],
                        "description": tab_parts[5].rstrip()
                        if len(tab_parts) > 5
                        else "",
                        "building": building,
                        "raw_line": line,  # Keep for debugging
                    }
                )

        elif directive == "VVRNG":
            tab_parts = re.split(r"\t+", line)
            if len(tab_parts) >= 5:
                rows.append(
                    {
                        "directive": "VVRNG",
                        "template": tab_parts[1],
                        "range": tab_parts[2],
                        "v6cidr": tab_parts[3],
                        "v4cidr": tab_parts[4],
                        "description": tab_parts[5].rstrip()
                        if len(tab_parts) > 5
                        else "",
                        "building": building,
                    }
                )

    # Build DataFrame
    this_df = pandas.DataFrame(rows) if rows else pandas.DataFrame()

    # Concatenate with children
    all_dfs = [this_df] + [df for df in child_dfs if not df.empty]

    if all_dfs and any(not df.empty for df in all_dfs):
        return pandas.concat(all_dfs, ignore_index=True)
    return pandas.DataFrame()


def populate_vlans(vlansdirectory, vlansfile):
    """Populate the vlan list from a vlans directory and file."""

    # Load all vlan data into a single DataFrame
    df = load_vlan_file(vlansdirectory, vlansfile)

    if df.empty:
        return []

    vlans = []

    # Process VLAN rows
    vlan_rows = df[df["directive"] == "VLAN"]
    for _, row in vlan_rows.iterrows():
        vlan_config = {
            "id": row["id"],
            "name": row["name"],
            "v6cidr": row["v6cidr"],
            "v4cidr": row["v4cidr"],
            "description": row["description"],
            "building": row["building"],
        }
        newvlan = make_vlan(vlan_config)
        if newvlan is not None:
            vlans.append(newvlan)

    # Process VVRNG rows
    vvrng_rows = df[df["directive"] == "VVRNG"]
    for _, row in vvrng_rows.iterrows():
        vlans.extend(
            gen_vlans(
                row["range"],
                row["template"],
                row["v6cidr"],
                row["v4cidr"],
                row["building"],
            )
        )

    # Sort by id
    vlans.sort(key=lambda v: int(v["id"]))

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

            # temporary, pre-pandas
            elems = re.split(r"\t+", line)
            vlan_config = {
                "id": elems[2],
                "name": elems[1],
                "v6cidr": elems[3],
                "v4cidr": elems[4],
                "description": elems[5].rstrip(),
                "building": building,
            }

            newvlan = make_vlan(vlan_config)
            if newvlan is not None:
                vlans.append(newvlan)
        elif directive == "VVRNG":
            line = current[0]
            building = current[1]
            # temporary, pre-pandas
            elems = re.split(r"\t+", line)
            vlans = vlans + gen_vlans(elems[2], elems[1], elems[3], elems[4], building)
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
            prefsplit + ":d8c::1000",  # 4096 addresses
        ]

    return [
        prefsplit + ":d8c::1",
        prefsplit + ":d8c::800",  # 2048 addresses
    ]


def dhcp4ranges(prefix, bitmask):
    """generates start and end IPv4 addresses + router for DHCP ranges"""
    if bitmask < 17 or bitmask > 24:
        return ["", "", "", "", ""]
    ipsplit = re.split(r"\.", prefix)
    if bitmask == 24:
        return [
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".80",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".254",
            ipsplit[0] + "." + ipsplit[1] + "." + ipsplit[2] + ".1",
        ]
    numocs = 2 ** (24 - bitmask)
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
    routers_df = pandas.read_csv(routersfile)
    routers_df.columns.str.strip()
    routers = []

    for _, row in routers_df.iterrows():
        name = row["name"].lower()
        ipv6 = row["ipv6"]

        routers.append(
            {
                "name": name,
                "ipv6": ipv6,
                "ipv6ptr": ip6toptr(ipv6),
                "fqdn": name + ".scale.lan",
            }
        )

    return routers


def populateaps(aps_file, apuse_file):
    """populate the AP list from an APs files"""
    aps_df = pandas.read_csv(aps_file)
    apuse_df = pandas.read_csv(apuse_file)

    aps_df.columns = aps_df.columns.str.strip()
    apuse_df.columns = apuse_df.columns.str.strip()

    merged_df = apuse_df.merge(
        aps_df, left_on="serial", right_on="serial", suffixes=("", "_ap")
    )

    aps = []
    for _, row in merged_df.iterrows():
        name = row["name"].lower()
        ipv4 = row["ipv4"]

        aps.append(
            {
                "name": name,
                "mac": row["mac"],
                "ipv4": ipv4,
                "ipv4ptr": ip4toptr(ipv4),
                "wifi2": str(row["2.4Ghz_chan"]),
                "wifi5": str(row["5Ghz_chan"]),
                "configver": str(row["config_ver"]),
                "fqdn": name + ".scale.lan",
                "aliases": [row["serial"].lower()],
            }
        )
    return aps


def populatepis(pis_file, piuse_file):
    """Populate the PI list from pis.csv and piuse.csv files"""
    pis_df = pandas.read_csv(pis_file)
    piuse_df = pandas.read_csv(piuse_file)

    pis_df.columns = pis_df.columns.str.strip()
    piuse_df.columns = piuse_df.columns.str.strip()

    merged_df = piuse_df.merge(
        pis_df, left_on="serial", right_on="serial", suffixes=("", "_pi")
    )

    merged_df["ipv6"] = (
        "2001:470:f026:" + merged_df["ip"].astype(str) + ":" + merged_df["eui64 suffix"]
    )

    pis = []
    for _, row in merged_df.iterrows():
        ipaddr = row["ipv6"]
        pi_name = row["name"].lower()

        pis.append(
            {
                "name": pi_name,
                "ipv6": ipaddr,
                "ipv6ptr": ip6toptr(ipaddr),
                "fqdn": pi_name + ".scale.lan",
            }
        )

    return pis


def serveralias(name):
    """generate aliases for servers. Rendered as CNAMES"""
    payload = []
    match name.lower():
        case "core-slave":
            payload = [
                "coreexpo",
                "ntpexpo",
            ]
        case "core-master":
            payload = [
                "coreconf",
                "loghost",
                "monitoring",
                "ntpconf",
                "signs",
            ]
    return payload


def roomalias(name):
    """generates room name based alias names for switches"""
    payload = []
    upname = name.upper()
    if "RM" in upname and "-" in name:
        comrooms = re.split("RM", upname)[1]
        comrooms = comrooms.replace("\n", "")
        rooms = re.split("-", comrooms)
        for room in rooms:
            payload.append(f"rm{room}")
    return payload


def populateservers(serversfile, vlans):
    """populate the server list from a servers file"""
    servers_df = pandas.read_csv(serversfile)
    servers_df.columns.str.strip()
    servers = []

    for _, row in servers_df.iterrows():
        name = row["name"]
        aliases = serveralias(name)
        ipv6 = row["ipv6"]
        ipv4 = row["ipv4"]

        # let's bail if either ip is invalid, which also skips
        # unused server entries as well (where ip is blank)
        if not isvalidip(ipv6) or not isvalidip(ipv4):
            continue

        vlan = ""
        building = ""
        for vln in vlans:
            if ipv6.find(vln["ipv6prefix"]) == 0:
                vlan = vln["name"]
                building = vln["building"]

        servers.append(
            {
                "name": name,
                "macaddress": row["mac-address"],
                "role": row["role"],
                "ipv6": ipv6,
                "ipv6ptr": ip6toptr(ipv6),
                "ipv4": ipv4,
                "ipv4ptr": ip4toptr(ipv4),
                "vlan": vlan,
                "fqdn": name + ".scale.lan",
                "building": building,
                "aliases": aliases,
            }
        )
    return servers


def populatedhcpnameservers(servers, vlans):
    coreservers = [x for x in servers if x["role"] == "core"]
    for i, _ in enumerate(vlans):
        vlans[i]["ipv6dns1"] = coreservers[0]["ipv6"]
        vlans[i]["ipv4dns1"] = coreservers[0]["ipv4"]
        if len(coreservers) > 1:
            vlans[i]["ipv6dns2"] = coreservers[1]["ipv6"]
            vlans[i]["ipv4dns2"] = coreservers[1]["ipv4"]


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
                "interfaces": ["@@INTERFACE@@"],
                "service-sockets-max-retries": 5,
                "service-sockets-retry-wait-time": 5000,
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
                    "data": ",".join(
                        [x["ipv4"] for x in servers if x["role"] == "core"]
                    ),
                },
                {
                    "name": "ntp-servers",
                    "data": ",".join(
                        [x["ipv4"] for x in servers if x["role"] == "core"]
                    ),
                },
                {"name": "domain-name", "data": "scale.lan"},
                {"name": "domain-search", "data": "scale.lan"},
            ],
            "option-def": [
                {
                    "name": "radio24-channel",
                    "code": 224,
                    "type": "string",
                    "array": False,
                    "record-types": "",
                    "space": "dhcp4",
                    "encapsulate": "",
                },
                {
                    "name": "radio5-channel",
                    "code": 225,
                    "type": "string",
                    "array": False,
                    "record-types": "",
                    "space": "dhcp4",
                    "encapsulate": "",
                },
                {
                    "name": "ap-network-config",
                    "code": 226,
                    "type": "string",
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
            "subnet4": [],
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
                # TODO: Better definition of for populating this
                "interfaces": ["@@INTERFACE@@", "@@INTERFACE@@/@@SERVERADDRESS@@"],
                "service-sockets-max-retries": 5,
                "service-sockets-retry-wait-time": 5000,
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
                    "data": ",".join(
                        [x["ipv6"] for x in servers if x["role"] == "core"]
                    ),
                },
                {
                    # option 56 which deprecates option 31 (RFC 4075)
                    # https://www.rfc-editor.org/rfc/rfc5908
                    # this option itself is empty but has associated sub-options (1-3)
                    "name": "ntp-server",
                },
                {
                    # option 56 requires at least one sub-option
                    # https://kea.readthedocs.io/en/kea-3.0.0/arm/dhcp6-srv.html#ntp-server-suboptions
                    # either name or code is sufficient to identify the sub-option but prefer to be explicit
                    "name": "ntp-server-address",
                    "code": 1,
                    "space": "v6-ntp-server-suboptions",
                    "data": ",".join(
                        [x["ipv6"] for x in servers if x["role"] == "core"]
                    ),
                },
                {"name": "domain-search", "data": "scale.lan"},
            ],
            "option-def": [],
            "reservations-global": True,
            "reservations-in-subnet": False,
            "reservations": [],
            # Finally, we list the subnets from which we will be leasing addresses.
            "subnet6": [],
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
        # TODO: filtering out vlan 112 for the soda machine
        if vlan["ipv4bitmask"] == "0" or vlan["id"] == "112":
            continue
        else:
            subnet = {
                "subnet": vlan["ipv4prefix"] + "/" + str(vlan["ipv4bitmask"]),
                # generating uniq id (prefix with dots) for each subnet block to ensure autoids dont effect reordering
                # called out in: https://kea.readthedocs.io/en/latest/arm/dhcp4-srv.html#ipv4-subnet-identifier
                # subnet ids must be greater than zero and less than 4294967295
                "id": int(vlan["ipv4prefix"].replace(".", "")),
                "user-context": {"vlan": vlan["name"]},
                "pools": [
                    {"pool": vlan["ipv4dhcpStart"] + " - " + vlan["ipv4dhcpEnd"]}
                ],
                "option-data": [
                    {"name": "routers", "data": str(vlan["ipv4router"])},
                ],
            }
            # lower lease times for the APs
            if vlan["name"] in ["cfInfra", "exInfra"]:
                # Set lifetime of lease to always be 300 seconds
                subnet["valid-lifetime"] = 300
                subnet["min-valid-lifetime"] = 300
                subnet["max-valid-lifetime"] = 300
            subnets_dict.append(subnet)

    kea_config["Dhcp4"]["subnet4"] = subnets_dict
    kea_config["Dhcp4"]["reservations"] = reservations_dict

    with open(f"{outputdir}/dhcp4-server.conf", "w") as f:
        f.write(json.dumps(kea_config, indent=2))

    subnets6_dict = []
    for vlan in vlans:
        # Make sure to skip vlans that have no ranges
        # TODO: filtering out vlan 112 for the soda machine
        if vlan["ipv6bitmask"] == "0" or vlan["id"] == "112":
            continue
        else:
            subnet = {
                "subnet": vlan["ipv6prefix"] + "/" + str(vlan["ipv6bitmask"]),
                # generating uniq id (prefix with dots) for each subnet block to ensure autoids dont effect reordering
                # called out in: https://kea.readthedocs.io/en/latest/arm/dhcp4-srv.html#ipv4-subnet-identifier
                # subnet ids must be greater than zero and less than 4294967295
                #
                # for ipv6 well take the last 4 hex digits to make sure the id is small enough but uniq
                "id": int(vlan["ipv6prefix"].replace(":", "")[-4:], 16),
                "user-context": {"vlan": vlan["name"]},
                "pools": [
                    {"pool": vlan["ipv6dhcpStart"] + " - " + vlan["ipv6dhcpEnd"]}
                ],
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
                subnet["interface"] = "@@INTERFACE@@"
            subnets6_dict.append(subnet)

    keav6_config["Dhcp6"]["subnet6"] = subnets6_dict

    with open(f"{outputdir}/dhcp6-server.conf", "w") as f:
        f.write(json.dumps(keav6_config, indent=2))


def generatepromconfigs(pis, aps, outputdir):
    prom_ap_config = [
        {
            "targets": [ap["ipv4"] + ":9100"],
            "labels": {"ap": ap["name"]},
        }
        for ap in aps
    ]

    with open(f"{outputdir}/prom-aps.json", "w") as f:
        f.write(json.dumps(prom_ap_config, indent=2))

    prom_pi_config = [
        {
            "targets": [f"[{pi['ipv6']}]:9100"],
            "labels": {"pi": pi["name"]},
        }
        for pi in pis
    ]

    with open(f"{outputdir}/prom-pis.json", "w") as f:
        f.write(json.dumps(prom_pi_config, indent=2))


def generatezones(switches, routers, pis, aps, servers, outputdir):
    content = ""
    for batch in [switches, routers, pis, aps, servers]:
        zonetemplate = jinja2.Template("""
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
""")
        content += zonetemplate.render(batch=batch)
    with open(f"{outputdir}/db.scale.lan.records", "w") as f:
        f.write(content)
    # ipv4 and ipv6 ptr zones need to be in different zone files
    for ip in ["ipv4", "ipv6"]:
        content = ""
        for batch in [switches, routers, pis, aps, servers]:
            zonetemplate = jinja2.Template("""
{% for item in batch -%}
{%- set ptr = ip + 'ptr' -%}
{% if item[ptr] -%}
{{ item[ptr] }}.  IN  PTR    {{ item['fqdn'] }}.
{% endif -%}
{% endfor -%}
""")
            content += zonetemplate.render(batch=batch, ip=ip)
        with open(f"{outputdir}/db.{ip}.arpa.records", "w") as f:
            f.write(content)

    return True


def generatewasgehtconfig(switches, routers, pis, aps, servers, outputdir):
    wasgehtconfig = {}
    for switch in switches:
        wasgehtconfig[switch["name"]] = {"address": switch["ipv6"]}
    for router in routers:
        wasgehtconfig[router["name"]] = {"address": router["ipv6"]}
    for pi in pis:
        wasgehtconfig[pi["name"]] = {"address": pi["ipv6"]}
    for ap in aps:
        wasgehtconfig[ap["name"]] = {"address": ap["ipv4"]}
    for server in servers:
        wasgehtconfig[server["name"]] = {"address": server["ipv6"]}
    wasgehtconfig["google88v6"] = {"address": "2001:4860:4860::8888"}
    wasgehtconfig["google88v4"] = {"address": "8.8.8.8"}
    wasgehtconfig["google44v6"] = {"address": "2001:4860:4860::8844"}
    wasgehtconfig["google44v4"] = {"address": "8.8.4.4"}
    wasgehtconfig["localhost"] = {"address": "::1"}
    with open(f"{outputdir}/scale-wasgeht-config.json", "w") as f:
        json.dump(wasgehtconfig, f)


def generateallnetwork(switches, routers, outputdir):
    hostlist = []
    for switch in switches:
        hostlist.append(switch["fqdn"])
    for router in routers:
        hostlist.append(router["fqdn"])
    for h in hostlist:
        with open(f"{outputdir}/all-network-devices", "a") as f:
            f.write(f"{h}\n")


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
    pifile = "../facts/pi/pis.csv"
    piusefile = "../facts/pi/piuse.csv"

    # populate the device type lists
    vlans = populate_vlans(swconfigdir, vlansfile)
    switches = populateswitches(switchesfile)
    servers = populateservers(serversfile, vlans)
    routers = populaterouters(routersfile)
    aps = populateaps(apsfile, apusefile)
    pis = populatepis(pifile, piusefile)

    subcomm = sys.argv[1]
    outputdir = sys.argv[2]
    if not os.path.exists(outputdir):
        os.makedirs(outputdir)

    if subcomm == "kea":
        generatekeaconfig(servers, aps, vlans, outputdir)
    elif subcomm == "nsd":
        generatezones(switches, routers, pis, aps, servers, outputdir)
    elif subcomm == "prom":
        generatepromconfigs(pis, aps, outputdir)
    elif subcomm == "wasgeht":
        generatewasgehtconfig(switches, routers, pis, aps, servers, outputdir)
    elif subcomm == "allnet":
        generateallnetwork(switches, routers, outputdir)
    elif subcomm == "all":
        generatekeaconfig(servers, aps, vlans, outputdir)
        generatezones(switches, routers, pis, aps, servers, outputdir)
        generatepromconfigs(pis, aps, outputdir)
        generatewasgehtconfig(switches, routers, pis, aps, servers, outputdir)
        generateallnetwork(switches, routers, outputdir)
    elif subcomm == "debug":
        # overload outputdir as 2nd debug parameter
        debug_variable = outputdir
        # valid variables to inspect
        valid_debug_variables = {
            "switches": switches,
            "routers": routers,
            "vlans": vlans,
            "servers": servers,
            "aps": aps,
            "pis": pis,
        }
        if debug_variable in valid_debug_variables.keys():
            print(json.dumps(valid_debug_variables[debug_variable]))
        else:
            print(f"invalid debug variable {debug_variable}")
    else:
        print("invalid subcommand")


if __name__ == "__main__":
    main()
