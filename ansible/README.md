## Playbook for SCaLE Server Infrastructure

This playbook is used for deploying and maintaining the SCaLE Server Infrastructure. 

Status:
  * Vagrant environment built with 4 VMs, IPv4 assigned for test, IPv6 pre-assigned
  * Some basic roles implemented but none considered complete.

Target Features:
  * DNS services with unbound
  * DNS views to support per building responses for loghost record
  * DHCP with ISC DHCP Server with per building vlans/pools
  * NTP with openntpd
  * Syslog with per building logging, then ship from expo to conference
  * Zabbix host additions done dynamically (awaiting Pi, AP, and Switch IP lists to consume)
  * Central server for ansible and image building tools

Requirements:
  * vagrant 2.0.1
  * virtualbox 5.2
  * ansible 2.4

### Usage

#### At SCaLE:

Process TBD

#### Vagrant:

Issuing the __vagrant up__ command will build all vms and kick off the ansible playbook.

After the files are modified issue the __vagrant up__ command followed by the __vagrant provision__ command.

Due to the way the Vagrantfile is structured, issuing the __vagrant__ command followed by the vm name will not kick off the ansible playbook.

todo:
  * fix DNS views in unbound
  * implement scale.lan zone in unbound
  * implement dynamic inventory scripts to consume AP, pi, and switch lists once they exist
  * implement rsyslog shipping
  * implement rsyslog client
  * implement ntpd client
  * implement zabbix
  * implement zabbix checks from dynamic lists
  * implement sign server