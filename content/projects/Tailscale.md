---
title: Tailscale Setup
type: page
tags:
  - homelab
  - tailscale
  - vpn
showTableOfContents: true
---
## The Problem
I set up my home lab with three VLANs. My main VLAN, where all of our personal devices connect, a VLAN for smart devices to keep them separated from our personal network, and a VLAN for homelabbing. 

I was looking for a way to connect to my homelab from my personal devices to do development work, without affecting my actual network. Initially, the plan was a traditional self-hosted VPN like Wireguard but it was going to require port forwarding and other firewall workarounds that I was just not comfortable with on my personal network.

In comes Tailscale.

### What is Tailscale?
Tailscale is a virtual private network. Traditional VPNs work by client devices authenticating and connecting to a main VPN server on. Tailscale is a "mesh" network. This mesh network allows all devices on the network to connect to each other, without requiring a main server.

When first setting up Tailscale, you create what they refer to as a "Tailnet", which is the network all devices on the network connect to to communicate. Setup for client devices is often as simple as downloading Tailscale, usually through the app store but can also be done via command line. Once downloaded, you log in as your user and enable Tailscale on the client device. It's really that simple (there is a setting to require approval before allowing a device to connect). 

#### Exit Nodes
This basic setup alone does not fully function like a traditional VPN. Tailscale only routes tailnet traffic to other devices on the tailnet, so anything leaving the tailnet is untouched by Tailscale. Region-locked content, public wifi privacy, and other VPN scenarios require one of the devices to act as an "exit node", this way, all traffic leaving the tailnet is routed through the exit node, making it look like all traffic is on that one device. Exit nodes also encrypt all traffic that leaves the network.

#### Subnet Routers
Not all devices can simply download Tailscale, or you may be in a scenario where you just don't want to or can't feasibly download Tailscale on all client devices. To set up a device that does not have Tailscale installed, a tailnet device will need to "advertise subnet routes". This "subnet router" sends traffic between the tailnet and traditional subnet. 

### The Approach
How to set up Tailscale on eligible devices
- List of available devices and how to install can be found [here](https://tailscale.com/kb/1347/installation) but here is a simple guide
1. Navigate to [login.tailscale.com](login.tailscale.com)
2. Create an account
3. Download Tailscale via:
	1. Tailscale website
	2. Google Play Store
	3. Apple App Store
	4. Command line
		1. Run the following commands:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```
		2. Navigate to the url that is output from above command
		3. Sign In
### How to set up an Exit Node
1. From Command Line:
	1. Run the following command on the device you want to act as the exit node:
```bash
sudo tailscale set --advertise-exit-node
sudo tailscale up
```
2. From web/mobile app:
	1. Log in
	2. Select device you want to act as exit node
	3. Select "Machine Settings" then "Edit Route Settings"
	4. Check "Use Exit Node"
3. See [here](https://tailscale.com/kb/1103/exit-nodes) for more details

### How to set up a Subnet Router
1. From Command Line:
	1. Advertise subnet routes with the following command:
```bash
sudo tailscale set --advertise-routes=192.0.2.0/24,198.51.100.0/24
```
2. See [here](https://tailscale.com/kb/1019/subnets) for more details

### The Impact
1. Differences between a traditional VPN and a mesh VPN
2. Tailscale setup and basic admin