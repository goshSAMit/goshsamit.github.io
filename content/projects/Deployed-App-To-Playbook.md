---
title: Creating an Ansible Playbook from a Deployed Application
type: page
tags:
  - homelab
  - iac
  - devops
  - ansible
date: 2026-04-15
showTableOfContents: true
---
## The Problem
The time has arrived in my ever growing quest to learn DevOps and Infrastructure-as-Code, to take an already deployed kubernetes application, and convert it into an automated and consistent Ansible Playbook.

## The Approach
### A. Plays and Playbooks
Ansible uses "playbooks" to group "plays" together. These plays run the configuration changes that take place on specified hosts in the "inventory file." So, "on these hosts, run these plays as a part of this playbook." In our situation, each application will be it's own playbook, with plays that run on the cluster to configure the application as needed.

This will not be a step-by-step guide. I plan to write a "code review" post for this work and will explain in greater detail there.
### B. Deployed Application to Ansible Playbook
We can take the configuration of the already-deployed-application and convert that into a template file (template_name.yaml.j2 - the .j2 extension tells ansible this is a templated file). From there, our playbook will specific a role to run, and that role includes the tasks it will run through to configure the application.

So, for example, the playbook homepage.yml includes the simple playbook:
```yaml
- name: Deploy homepage dashboard
hosts: server
gather_facts: false
roles:
- homepage
```
When you run this playbook, it tells the homepage role to start going through its tasks: 
```
- name: Ensure pip is installed #pre-req
- name: Ensure kubernetes Python library is installed #pre-req
- name: Apply homepage PV
- name: Ensure homepage namespace exists
- name: Apply homepage PVC
- name: Apply homepage Deployment
- name: Apply homepage Service
- name: Apply homepage Ingress
```
If you follow the guide on [manual deployment](https://goshsamit.com/projects/manual-deploy/) of a kubernetes app, the steps for manual deployment closely match the plays for the playbook. The biggest difference is that the "Apply homepage PV" step replaces the ConfigMap steps for manual deployment. The Persistent Volume (PV), houses a directory where the config files for homepage live. 
### C. Why deploy manually at all?
While working on this, it sort of felt like I was duplicating effort to get to the same end goal of the deployed Homepage dashboard. However, we can create the templates the Ansible playbook/roles need from configuration files created during kubernetes deployment.

Run the following command on the master node of the cluster running the manually deployed Homepage dashboard:
```bash
kubectl get deployment,svc,ingress,pvc,configmap -n homepage -o yaml`
```
The results of each of this will be their own template.yml.j2 file. There are some lines that need excluded, but it's a good starting place. I plan to compare the results from this command to what the templates actually look like in a future post.
## The Impact
- Learning the manual deployment first makes the anisble playbook creation easier is pretty useful. By running one command, you can basically get the configuration needs for the playbook templates. Then then plays basically copy the templates and fill in appropriate information.