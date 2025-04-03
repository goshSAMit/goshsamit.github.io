---
title: Homepage Dashboard
type: page
tags:
  - homelab
  - homepage
date: 2025-04-03
showTableOfContents: true
---
## Intro
Homepage is a simple dashboard allowing users to set up a single page to get a quick view of services running on their network, resource utilization, and important links. It's also a good project to start working with docker containers, as you can create a docker container to run your homepage instance, which is what this guide will show. 

## Steps
1. Install docker and docker compose [with this guide]("https://goshsamit.com/how-to-install-docker-and-docker-compose-on-ubuntu")
2. On your docker machine (mine is a VM running Ubuntu server), create a folder where you want to keep your homepage files
```
mkdir homepage
```
3. "CD" into that directory
```
cd homepage
```
4. Create two new files inside that directory called "docker-compose.yaml" and .env
```
touch docker-compose.yaml $$ touch .env
```
- The docker-compose file is an easier way to create and configure docker containers
- The .env file will be used to store environment variables so you aren't hard coding ip addresses or user IDs and passwords directly into your homepage configuration files
5. Open the docker-compose file in the nano text editor
```
nano docker-compose.yaml
```
6. Copy and paste the following block into docker-compose.yaml file using a text editor like nano
```
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    ports:
      - 3000:3000
    env_file: .env # get environment variables from this file
    volumes:
      - ./config:/app/config # creates the config folder in the same director as this docker compose file
    environment:
      HOMEPAGE_ALLOWED_HOSTS: $HOMEPAGE_ALLOWED_HOSTS # read them from .env
      PUID: $PUID # read them from .env
      PGID: $PGID # read them from .env
```
7. In nano, press Ctrl + X to save, press 'y' to say yes, and Enter to confirm
8. open the .env file in nano
```
nano .env
```
9. The following lines will be necessary for homepage functionality, we can add usernames/api tokens/urls later
```
HOMEPAGE_ALLOWED_HOSTS=192.168.30.200:3000
PUID=1000
PGID=1000
```
10. In nano, press Ctrl + X to save, press 'y' to say yes, and Enter to confirm
11. Now that the docker compose yaml and the environment variable files are set up, we can create the container with the following command and watch it do it's thing
```
sudo docker compose up -d
```
12. When that completes, you can run the following command to check the status of any running containers
```
sudo docker ps
```
13. Wait for the status of the new container to be "healthy" under status
!![Image Description](/images/Pasted%20image%2020250403123149.png)
14. Once that says "healthy", open a browser and go to "http://ip.addr:3000" and you should see the template page show up!
15. Back in your terminal window, inside the homepage directory, use the ls command, there should be a new directory named "config"
16. "CD" into that directory and use the ls command again, you should see a list of new yaml files
17. The files you want to customize/change are
	- bookmarks
	- services
	- settings
	- widgets
	- https://gethomepage.dev/ has a list of all of the services and widgets

## What did I learn?
- docker and docker compose basics
- Using API tokens instead of usernames and passwords
