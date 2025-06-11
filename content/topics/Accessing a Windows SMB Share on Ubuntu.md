---
title: Accessing a Windows SMB Share on Ubuntu
date: 2025-06-11
type: post
tags:
  - homelab
  - how-to
  - nas
---
### Install Packages
1. Make sure your packages with sudo apt update
2. Install the Samba Package, the SMB Client package, and the CIFS Utilities package
	1. The Samba package allows Ubuntu machines to share Windows resources
	2. SMB Client is a set of command line tools that allows Ubuntu to access Server Message Block (SMB)/Common Internet File System (CIFS) resources
	3. CIFS-Utils allows mounting SMB and CIFS file systems to an Ubuntu system
```console
sudo apt install samba smbclient cifs-utils
```

### Mount Directly in Ubuntu's File Explorer
1. Open File Explorer
2. Click 'Other Locations'
3. Enter the following in the Connect to Server text box:
	`smb://SHARE-IP-ADDRESS/NAME-OF-SHARE

### Mount to a directory using Terminal
1. Open the terminal
2. Create a directory in the /mnt folder to mount the drive to
```console
mkdir /mnt/share
```
3. Then mount the drive to that newly created directory
```console
sudo mount -t cifs //IP_ADDRESS_OF_SHARE/SHARE_NAME /mnt/share -o username=YOUR_USERNAME,password=YOUR_PASSWORD,uid=$(id -u),gid=$(id -g)
```
	   
3. (Optional) In the terminal, open the fstab file
```console
	sudo nano //etc/fstab
```
4. (Optional) Add the following line to the fstab file to make sure your share automatically mounts on restart
```console
\pard\pardeftab720\partightenfactor0
\cf2 //IP-address-of-share/share-name /mnt/share cifs username=your-username,password=your-password,uid=1000,gid=1000 0 0\
```
