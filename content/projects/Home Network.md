---
title: Home Network
type: post
tags:
  - homelab
  - vlan
  - dhcp
  - firewall
  - ssid
showTableOfContents: true
date: 2025-03-28
---
## Intro
This is a walk-through guide of how I set up home network and how to set up VLANs on a TP-Link Managed Switch.

My network at home is set into 3 Virtual Local Area Networks (VLAN). The first is VLAN 1, and it is the default network that my family's everyday devices connect to. The second is VLAN 20. It is for smart devices that have questionable security vulnerabilities. I buy devices that I generally trust, but you can't be too careful. Plus, this was a good way to help me understand VLANs a bit more. The third one is VLAN 30, and it is for my home lab devices. This way, I can make router, firewall, DNS, and other changes without interrupting anyone's network connectivity.

## PFSense - Create VLAN
1. Log into your PFSense Router/Firewall
2. Navigate to Interfaces -> Assignments
3. Select VLANs -> Add
!![Image Description](/images/step%203%20&%204.png)
4. Make the following configurations:
	1. Choose the interface the VLAN will be connected to (lan most likely)
	2. Add a unique VLAN ID number (any number between 1 and 4096)
	!![Image Description](/images/step%206%207.png)
5. Navigate to Interface -> Assignments
6. Select the VLAN from the drop-down 
7. Click Add
!![Image Description](/images/step%208%209.png)

## PFSense - Interface Configuration
1. Navigate to Interfaces -> VLAN Interface to edit
2. Make the following configurations:
	1. Enable the Interface
	2. Under static IPv4, set the IP address that you want the gateway/router to be
!![Image Description](/images/Step%201%202%203.png)
## PFSense DHCP Server
1. Navigate to Services -> DHCP Server
2. Select the interface you want to configure
3. Make the following configurations:
	1. Enable the DHCP Service
	2. Select the IP address range that the DHCP Server should hand out to new clients/devices
	3. Add DNS server(s) the DHCP should hand out to new devices/clients
	4. Add Static Mapping for any device you do not want the IP address to change (should be outside of range in step 3.2)
		1. Enter MAC Address of the device
		2. Enter the IP Address the device should have
		3. Give it a hostname and description

## PFSense - Firewall Setup for VLANs
This firewall setup will be to prevent traffic from one VLAN from having any access to traffic on a separate VLAN.
1. Navigate to Firewall -> Rules
2. Set VLAN interface firewall rules to the following:
!![Image Description](/images/fstep%201%202%203.png)
## Set Up VLAN on TP-Link Omada Switch
This setup is for a specific device but should be relatively similar to most consumer manage switches.
1. Log in to switch
2. Navigate to L2 Features -> VLAN -> 802.1Q
3. Click Add
!![Image Description](/images/steps%203%204.png)
4. Make the following configurations:
	1. Give the VLAN an ID number to match the ID you gave during the creation of the VLAN on PFSense
	2. Name the VLAN
	3. Select ports for untagged traffic
	4. Select ports for tagged traffic
!![Image Description](/images/steps%205%206%207.png)
## Extra - Add a Wireless Network to a VLAN
If you plan to have wireless devices connecting to one of your new VLANs, use the following steps. As mentioned above, these steps are for a specific TP-Link Wireless Access Point (WAP) but should be similar to other consumer WAPs.
1. Log in to WAP
2. Navigate to Wireless
!![Image Description](/images/step%201.png)
3. Check whether you want to add a 2.4Hz or a 5Hz SSID
4. Click Add and make the following configurations:
	1. Name (will be displayed on devices when searching for a wireless network)
	2. Security type
	3. Encryption type
	4. Password
	5. Make the SSID and Password the same for both a 2.4Hz and 5Hz network so there is no need to log into both separately
!![Image Description](/images/step%203.png)
5. Navigate to VLAN
6. Enable the VLAN for the SSID
7. Add the VLAN ID that matches what was set up in PFSense
8. The port the WAP is plugged into the on the other switch will need to be tagged with the VLAN ID (see previous section)
!![Image Description](/images/step%204%205%206.png)
## What Did I Learn?
- VLAN Creation
- [Tagged vs. Untagged VLAN Traffic](https://goshsamit.com/topics/tagged-and-untagged-vlans/)
- Basic Firewall Rules
- DHCP Server Setup