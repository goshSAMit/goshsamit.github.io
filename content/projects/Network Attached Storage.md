---
title: Network Attached Storage
type: page
tags:
  - homelab
  - nas
date: 2025-03-01
showTableOfContents: true
---
### What is Network Attached Storage?
Networked attached storage, or NAS, is a storage device that can be access through a network, rather than being directly connected to a device. Basically, it's a portable hard-drive that anyone on the network can access (but is not actually portable). Users directly accessing the network as well as users outside the network but using a VPN to remotely connect to the network can access a NAS.

### TrueNAS
Part of the reason behind this project, was to learn more about NAS setup and configuration. Another reason is that I am hoping to slowly move away from large cloud storage providers and be more in control of the digital content that I create, consume, and save. After some research, I decided to go with TrueNAS as my self-hosted NAS solution. The other popular option was Unraid, however, comparing features, TrueNAS fit my use-cases more.

This is not going to be a complete walk-through of how I set it up. General set up of TrueNAS is relatively straightforward.
1. You download the TrueNAS .iso and use a software like Rufus to create a bootable USB drive.
2. Plug that drive into whatever device you plan to host TrueNAS. In my case, I used a Proxmox Virtual Machine, so I downloaded the .iso directly onto my Proxmox server.
3. Go through the installation steps and reboot the device. I'd recommend setting going onto your router and setting up a static IP address instead of using DHCP, you'll want this address to remain constant every time the device comes online.
4. Once you have the IP Address, you can open a web browser and navigate to that IP address.
5. From here, you'll need to create a pool. A pool on TrueNAS is a collection of hard drives and how they are configured with RAID (more later). 
6. After you've created a pool, you'll want to create a share. I have a little article about the differences between an SMB share and NFS share [here](https://goshsamit.com/topics/accessing-an-smb-share-on-ubuntu/), but I'd recommend starting with an SMB share, assuming you are using Windows devices.
7. Once that share is created, you'll configure the access control and then can use your account to connect to the share and start saving your files.

### Redundant Array of Independent Disks (RAID)
The key part of RAID is redundancy. There are various levels of RAID and each can offer varying levels of performance and redundancy. Each level requires a specific number of hard drives/disks to function.

| RAID Level |                                                                                                                                                    Function                                                                                                                                                     | Number of Drives needed |
| :--------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: | :---------------------: |
|     0      |            Striping - Data is split and stored on multiple drives, allowing both drives to work at the same time to read/write data. This allows for better performance versus a single drive, but completely skips redundancy. Losing one drive is enough to lose all the data stored in the pool.             |        2 or more        |
|     1      |               Mirror - Data is duplicated and stored on multiple drives. This requires twice as much storage capacity than a single drive, but this allows for the loss of a drive. If a drive is lost, you have time to replace it and configure it back into the pool to keep the data stored.                |        2 or more        |
|     5      |    Striped with Parity - Similar to RAID 0 but this requires a full drive to store "parity" data. This allows for the rebuilding data in case a drive is lost. This can lead to lower performance than a RAID 0 but in return, you get more redundancy than RAID 0, and lower disk utilization than RAID 5.     |        3 or more        |
|     10     | Stripe of Mirrors - This is the best of RAID 0 and RAID 1 (hence RAID 10). This stripes data like RAID, but mirrors that data like RAID 1. This allows for the better performance associated with RAID 0, and better redundancy associated with RAID 1. However, it also requires the largest number of drives. |        4 or more        |

There are several other levels of RAID, but these appear to be the most common. I learned about RAID levels while studying for the Comptia A+ certificate. It was nice being able to think about which level of RAID was going to be appropriate for me. A major part of the deciding factor is not only what level of performance and redundancy you want, but also the cost of achieving that specific level. So RAID 10 sounds like a best-of-all-worlds until you realize you need twice as many disks as you do for RAID 0 and RAID 1. Ultimately, my decision was to start with RAID 1 and see how quickly that fills up.

### What did I learn?
- The differences between SMB shares and NFS shares, as well as how to access SMB shares on Linux devices.
- How to mount a new share in Windows, Mac, and Linux.
- The different RAID levels available for storage pools.