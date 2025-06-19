---
title: Traefik and PiHole
type: page
tags:
  - homelab
  - docker
  - dockercompose
  - certs
  - dns
date: 2025-06-19
showTableOfContents: true
---
### Project
I was getting tired of entering IP addresses and having to click through the "connection not secure" messaging to get into my homelab services. I found a video by TechnoTim on YouTube where he walks through the "how-to's" of setting up Traefik as a cert manager and local DNS records on PiHole. So instead of copying his tutorial, I will just link it here.

- [TechnoTim's website with tutorial](https://technotim.live/posts/traefik-3-docker-certificates/)
- [TechnoTim's Youtube tutorial](https://www.youtube.com/watch?v=n1vOfdz5Nm8)

### Domain Name System
Part of this project focuses on creating local Domain Name System (DNS) records, which allow you to access services in a browser using domain names instead of IP addresses. At it's very basic, DNS servers translate human-readable website domains to network-readable IP addresses. PiHole allows us to create local DNS records that only devices on our local network will use. 

When a user enters a URL of a website into a browser for the first, a lot happens in a very short amount of time. 
1. The browser will send a request to its DNS server asking "what is the IP address of example.com"?
2. The DNS server, or resolver, checks it's records for this domain name. 
3. If the DNS resolver does not have an A record for example.com, it will reach out to a root server. There are a small number of these in the world (about 13) and they hold the records for all Top Level Domain (TLD) Servers.
4. The Root Server tells your DNS resolver "I'm not sure where example.com is specifically, but here is the TLD server for .com domain names."
5. This next server is the TLD server. It has A Records for all domains in the .com domain. So in our example, the TLD server provides our DNS resolver with the IP address of example.com's name server.

An A record is the most basic form of a DNS record. A records are responsible for returning the IP address of a domain. So the A Record for example.com would look something like this:
```
example.com IN A 192.168.0.1
```

Canonical Names (CNAME) allow a host to have more than one domain name. In the case of example.com, you could create a CNAME record for email.example.com. The CNAME record would look something like this:
```
email.example.com IN CNAME example.com
```

So for this project, in PiHole, we can create a local A record that uses the domain name of our Traefik server and links it to its IP Address. After that, for every service behind our Traefik server, we can set up a CNAME record with the domain name we would like to use (service1.example.com, service2.example.com) and assign it to the A record's domain. We can then configure Traefik to take this CNAME that is requested by a user and route it to the servers IP address.

### Certificate Verification
The second part of this project was to get rid of that "certificate not valid" message when accessing a local service. Certificates put the “Secure” in HTTPS (Hypertext Transfer Protocol Secure). They ensure that all communication between your browser and a remote server is encrypted. Without a certificate, your browser defaults to plain HTTP, meaning anyone on the network could intercept and read the traffic.

The certificate management process for this project works like this:
	1. Set up an A Record and CNAME records for services in PiHole.
	2. Set up a Traefik Proxy server and connect it to a Cloudflare account that has a verified domain. 
	3. In a browser, visit a service with one of the CNAME records, like service1.example.com. 
	4. The browser then reaches out to that Traefik server with the A Record it was provided and begins the certificate verification process. 
	5. Traefik uses Let's Encrypt to create and verify a wildcard certificate for service1.example.com
	6. Let's Encrypt uses Cloudflare to verify that we actually own the example.com domain.
	7. Traefik presents the verified certificate to the browser.
	8. The browser verifies the certificate is from a valid DNS provider.
	9. Traefik sends the browser to the IP address of service1.example.com and the traffic between the two is now secure (usually represented by a lock symbol next to the url in your browser's address bar).

### What did I learn?
1. Docker and Docker Compose
2. Setting up local A and CNAME domain records
3. Certificate Management and Verification