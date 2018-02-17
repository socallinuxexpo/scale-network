# Ansible CM for SCaLE Server Infrastructure

This playbook is used for deploying and maintaining the SCaLE Server Infrastructure using Ansible. 

#### Status:
  * Vagrant environment built with 4 VMs, IPv4 assigned for test, IPv6 pre-assigned
  * Dynamic inventory script for Ansible
  * Some basic roles implemented but none considered complete.

#### Target Features:
  * DNS services using BIND
  * DHCP services using ISC DHCP Server 
  * NTP with openntpd
  * Syslog 
  * Zabbix Monitoring with dynamic host addition
  * Central server for ansible and image building tools
  * Signs server deployment 

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

Issuing the __vagrant up__ command will build all vms and kick off the ansible playbook.

After the files are modified issue the __vagrant up__ command followed by the __vagrant provision__ command.

The vagrant environment uses ipv4 for management. The inventory will be modified during the show to use ipv6.

#### invetory.py

inventory.py is dynamic inventory script written in python. it generates json in a format ansible
expects generated dynamically by reading in the following files:

* vlansddir = "../switch-configuration/config/vlans.d/"
* switchesfile = "../switch-configuration/config/switchtypes"
* serverfile = "../facts/servers/serverlist.tsv"
