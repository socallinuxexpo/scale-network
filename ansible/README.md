# Ansible CM for SCaLE Server Infrastructure

This playbook is used for deploying and maintaining the SCaLE Server Infrastructure using Ansible. 

#### Features:
  * DNS services using BIND9
    * Dynamically generated zone files
    * Supports NS, AAAA, A, and PTR records
    * Zone files versioned and backed up locally
    * Support for DNS views
    * Dynamically generated view ACLs
  * NTP services
    * Single role supports client/server 

#### Requirements:
  * vagrant 2.0.1
  * virtualbox 5.2
  * ansible 2.4
  * python 2.7

### Usage

##### At SCaLE:

* change "ansible_host": s["ipv4"] to "ansible_host": s["ipv6"] in the inventory.py

further processes TBD

#### Vagrant:

The vagrant environment is hardcoded with 4 VMs. It uses ipv4 for management. The inventory will be modified during the show to use ipv6.

Issuing the __vagrant status__ command will display the state of the vms.

Issuing the __vagrant up__ command will build all vms and kick off the ansible playbook.

Issuing the __vagrant provision__ command will rerun the playbook.

Issuing the __vagrant destroy -f__ command will destroy all running vms.

#### invetory.py

inventory.py is dynamic inventory script written in python. it generates json in a format ansible
expects generated dynamically by reading in the following files:

* vlansddir = "../switch-configuration/config/vlans.d/"
* switchesfile = "../switch-configuration/config/switchtypes"
* serverfile = "../facts/servers/serverlist.tsv"
* apfile = "../facts/aps/aplist.tsv"
* pifiles = "../facts/pi/pilist.tsv"
