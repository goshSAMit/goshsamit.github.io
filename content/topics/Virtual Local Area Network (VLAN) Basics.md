---
title: VLAN Basics
date: 2025-04-09
type: post
tags:
  - topics
  - vlan
---

## Virtual Local Area Network (VLAN) Basics
In my home, I was looking for a way to keep my personal devices separate from any smart devices, as those devices can be less secure. One way I could handle this is to set up two Local Area Networks (LAN), one for my personal devices and one for the smart devices. Each would have their own switch and connection to the router and neither would be able to talk to the other. 

On a small scale like this, having two switches isn't necessarily out of the question, but I'd rather avoid paying for multiple switches, having multiple switches take up physical space on my small network rack, and paying for two devices worth of electricity. These issue become worse as networks get larger and more complex.

An easy solution for this is to use Virtual Local Area Networks (VLANs), which allows configuration of each LAN on the same switch, with the same benefit that neither VLAN can communicate directly with the other. VLANs "logically" separate the networks instead of "physically" separating them. 

For my solution, I set up two VLANs, VLAN 1 for my personal devices (VLAN 1 is often times a default VLAN on a switch), and VLAN 20 for the smart devices in my home. So one switch has some ports configured for VLAN 1, and other ports connected for VLAN 20. 

Now, with two networks on the same switch, how can I have both of them connected to the outside Internet? I could have one port on each VLAN plugged into the router, which could work on my small network. However, problems arise as networks become larger and more complex. To solve this, we can designate one port on the switch as a "trunk port." This trunk port will plug into the router and carry traffic bound for both VLANs. The switch will then direct traffic to either VLAN depending on a tag added to an Ethernet frame. This tag will be added or removed by the trunk port on the switch as traffic comes in or out. 

While trunk ports carry tagged VLAN traffic, access ports carry untagged VLAN traffic, meaning these ports can only carry traffic for a single VLAN. 

The following are basic steps of tagged and untagged VLAN traffic:\
- Device A is connected to Switch 1 and Device B is connected to Switch 2.
- Both Devices are apart of VLAN 10.
1. Device A sends untagged traffic into Switch 1. this traffic includes no information about VLANs, only what is regularly included in an Ethernet frame.
2. Switch 1 receives Device A's traffic, determines it is a VLAN 10 device communicating with a VLAN 10 device on Switch 2, and places a VLAN 10 ID Tag inside the frame.
3. Switch 1 sends that newly tagged frame out of its trunk port, to Switch 2.
4. Switch 2 reads the VLAN 10 Tag, removes it, then sends it to the untagged port Device B is attached to.