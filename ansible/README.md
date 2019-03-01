# Ansible CM for SCaLE Server Infrastructure

This playbook is used for deploying and maintaining the SCaLE Server Infrastructure using Ansible. 

## Features:
  * DNS servers - bind9
    * Dynamically generated zone files
    * Supports IPv6 and IPv4 forward and reverse zones
    * Zone files versioned and backed up locally
    * Support for DNS views
    * Dynamically generated view ACLs
    * Logs each DNS request
  * DHCP servers IPv6 and IPv4 - isc-dhcp-server
    * Dynamically generated subnet definitions files using vlans.d
    * Supports IPv6 and IPv4
    * Prewired for potential host reservations
    * DNS servers assigned to favor same building
    * Allocation blocks split in half (modifyable at show time)
    * Automated backups when changes are made in /etc/dhcp/backup
    * Logs all DHCP activity
  * DNS client - systemd-resolved
    * Clients are configured to prefer IPv6 and the building local DNS server
  * NTP services
    * Single chrony role supports client/server
  * Tech Team
    * Auto create team user accounts and home dirs
    * Effortless passwordless sudo
  * SCaLE Signs
    * Automatically pulls down scale signs repo, builds as docker image, and wraps it up as a systemd service
    * Subsequent runs after an update to the repo will rebuild the container and restart service
    * Secrets management is still manual for twitter creds and requires rebuilding the container and restarting manually
  * Automatically updates via apt

## Requirements:
  * vagrant 2.1
  * virtualbox 5.2
  * ansible 2.6
  * python 3.7

## Usage

#### At SCaLE:

* change "ansible_host": s["ipv4"] to "ansible_host": s["ipv6"] in the inventory.py
* modify ../facts/servers/serverlist.tsv specifying 2 core servers
* deploy servers
* * use IPs and name from serverlist.tsv, 
* * establish and test network connectivty
* * set uniform username, password, and sudoer access on each system
* run `ansible-playbook -u <username> -k -K -i inventory.py etc/ansible/scale.yml`
* once ssh keys are deployed `ansible-playbook -u <username> -i inventory.py etc/ansible/scale.yml`

## Vagrant Commands:

The vagrant environment is hardcoded with 4 VMs. It uses ipv4 for management. The inventory will be modified during the show to use ipv6.

`vagrant status` - display the state of the vms

`vagrant up` - builds all vms and kick off the ansible playbook

`vagrant provision` - rerun the playbook

`vagrant destroy -f` - destroy all running vms

`vagrant ssh $SERVER` - ssh into $SERVER as the vagrant user, status will show server names

## Ansible Examples:

Here are some sample Ansible commands to get you started.

If `-u vagrant` enter password `vagrant` when prompted

`ansible -u vagrant -k -i inventory.py servers -m ping`

This "pings" the servers through ansible. It's not a network ping but rather an end to end test via ssh/python

`ansible -u owen -i inventory.py servers -a "ping6 -c 1 server1.scale.lan"`

The `-u` option with `-k` omitted assumes your authorized_key is in the repository. Issues single ping sourced from each server destined for server1

`ansible -u rob -i inventory.py core -a "tail -12 /var/log/query.log"`

`-i` denotes the inventory to load followed by the group or host name

`ansible -u steven -k -K -i myfile.txt pis -b -a "reboot"`

`-b` denote become root. `-K` will prompt for the become password, which by default is your sudo auth. `--become-method su` will opt to prompt for the `su` auth instead. Can be omitted if keys and sudoers files are used.

`ansible -u david -i inventory.py servers -m file -a "path=/tmp/file state=touch"`

`-m` specifies the file module. `-a` is a list of options for the module. use the `ansible-doc -l` to list all modules. `ansible-doc $MODULE` to see module specific documentation.

#### invetory.py

`inventory.py` is dynamic inventory script written in python. it generates json in a format ansible
expects generated dynamically by reading in the following files:

* vlansddir = "../switch-configuration/config/vlans.d/"
* switchesfile = "../switch-configuration/config/switchtypes"
* serverfile = "../facts/servers/serverlist.tsv"
* routerfile = "../facts/routers/routerlist.tsv"
* apfile = "../facts/aps/aplist.tsv"
* pifiles = "../facts/pi/pilist.tsv"
