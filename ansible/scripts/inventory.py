#!/usr/bin/env python

# Dynamic inventory script used to slurp in various 
# SCaLE specific text files to produce a sane inventory to ansible

import os
import re

# constants with locations to files or directories within the repo
vlansddir = "../../switch-configuration/config/vlans.d/"
serverfile = "../../facts/servers/serverlist.csv"

# globals
#
# vlans = []{name, id, ipv6prefix, ipv6bitmask, ipv4prefix, ipv4bitmask, building, description}
vlans = []
# servers = []{name, mac-address, ipv4, ipv6}
servers = []

# populatevlans() will populate the vlans dictionary
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

def Main():
    populatevlans()
    print(vlans)

if __name__ == "__main__":
    Main()
        