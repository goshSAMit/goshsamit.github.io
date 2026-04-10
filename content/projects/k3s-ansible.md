---
title: Configuring k3s with Ansible
type: page
tags:
  - homelab
  - ansible
  - iac
  - devops
date: 2026-03-27
showTableOfContents: true
---
## The Problem
There is no real problem here. I have manually deployed several applications on my home network. I am setting up Ansible to practice automating configuration management. I have already created proxmox nodes using Terraform. The plan now is to automate the configuration of the cluster. Ansible seems like a top recommendation from the homelab community.

## The Approach
### k3s-ansible Repo vs. From Scratch
When researching how to automate k3s configuration, I came across a github repo for this very purpose. So I had a choice ahead of me, create my own ansible playbooks from scratch, or use this repo. After some reddit rabbit holes and some Claude prompting, I decided the best route would be to use the community-maintained repo. Ultimately, I wanted the cluster up and running quickly and my setup will be fairly standard, as I'm just learning Anisble for the first time. In the future, I may "re-invent the wheel" and try my hand at my own Ansible playbook, but for now, the k3s-ansible repo will do just fine. 

Now that the decision has been made, let's get this cluster config automated.

1. Pull k3s-ansible repo in as [submodule](http://goshsamit.com/topics/git-submodule/).
2. Edit inventory file and change the IP addresses for the server and worker nodes.
3. Next, a token needs generated to connect to the cluster. On the device that is running Ansible, run the following command:
```bash
openssl rand -base64 64
```
4. The output of this command goes into the inventory.yml as the token.
5. Add a field in the inventory.yml for ansible_ssh_private_key_file. The value of this will be the private key used to ssh into the cluster.
```
  ansible_ssh_private_key_file: ~/.ssh/your_private_key
```
6. Right now, the token is in plain text, so anyone can see it to gain access to your cluster. Create an Ansible Vault Password File and change the permissions.
```bash
echo -n 'your-vault-password' > ~/.vault_pass
chmod 600 ~/.vault_pass
```
7. Add this line to the ansible.cfg file
```
vault_password_file = ~/.vault_pass
```
8. Encrypt the cloudflare token: 
```bash
ansible-vault encrypt_string 'your-token' \ --name 'vault_variable_name'
```
9. Copy the value and paste it into your inventory.yml
10. If you have red squiggles saying !vault is wrong, add this to .vscode/settings.json
```json
{
  "yaml.customTags": [
    "!vault scalar"
  ]
}
```
11. You can run this command to verify ansible can unencrypt the value, the result should be your token in plain text.
```bash
ansible -i inventory.yml k3s_cluster \
  -m debug \
  -a "var=vault_cloudflare_api_token" \
  --limit IP.OF.Control.Server
```
11. Finally, we will want to make sure the cluster has a shared storage system set up. Create a new playbook called storage.yml and include the following:
```yml
- name: Install storage dependencies
	hosts: k3s_cluster
	become: true
	tasks:
		- name: Install nfs-common
		apt:
		name: nfs-common
		state: present
```
8. Now run the playbook.
```shell
ansible-playbook playbooks/site.yml
```
9. As a final step, ensure your inventory.yml is included in .gitignore.
### The Impact
- I learned how to fork an existing repo and use it as a [submodule](http://goshsamit.com/topics/git-submodule/) Github.
- I learned how to encrypt a cluster token with ansible-vault.