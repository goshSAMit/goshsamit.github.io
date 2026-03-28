---
title: Terraform with Proxmox
type: page
tags:
  - homelab
  - terraform
  - iac
  - devops
showTableOfContents: true
---
## The Problem
There is no specific problem from this. I started using Terraform at work with Google Cloud and wanted some more practice with it.

## The Approach
### A. Install Terraform
I am starting this development on Ubuntu, Hashicorp's website has [detailed instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for downloading on different operating systems.

1. First step, as always with Linux, is to update your package manager.
```bash
sudo apt update
```
2. Terraform then requires the download of gnupg and software-property-commons packages.
```bash
sudo apt install -y gnupg software-properties-common
```
3. Next, download Terraform's gpg key.
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
```
4. Add the Terraform repository.
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
5. Update the repository.
```bash
sudo apt update
```
6. Finally, install Terraform.
```bash
sudo apt-get install terraform
```
7. To verify installation, check the version of Terraform.
``` bash
terraform -v
```

### B. Creating a Terraform user for Proxmox
1. Create a role for the Terraform to use when interacting with Proxmox.
```bash
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
```
2. Create the Terraform user (replacing password with your chose of password).
```bash
pveum user add terraform-prov@pve --password <password>
```
3. Assign the newly created role to the newly created user.
```bash
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

### C. Basic Terraform Project Structure
#### main.tf
The main.tf file is where the actual code to build the resources in Proxmox will be put. Typically, the file starts with a "providers" section that includes what platform Terraform will be using. Some common provider sources are AWS, Google Cloud, and Microsoft Azure, but in our case, we will use Proxmox. The below code blocks are going to vary for your chosen provider, this using bgp/proxmox provider. Its documentation can be found [here](https://registry.terraform.io/providers/bpg/proxmox/latest).
```terraform
provider "proxmox" {
	endpoint = var.proxmox_api_url
	api_token = var.api_token
	insecure = true
	ssh {
		agent = true
		private_key = file(var.private_key)
	}
}
```
 After our provider has been declared, we can add "resource" blocks to create the resources for the provider. We will use the bgp provider's `"proxmox_virtual_environment_container"` resource. We give the terraform resource a name for easy referral, and add fields based on what the resource requires to be created. Below is just a small section of the resource's fields. It will also include network config information, disk, memory, etc. Basically any options you have during set up of a container using proxmox GUI, will have a matching field with a terraform provider,
 ```terraform
resource "proxmox_virtual_environment_container" "cluster-node" {
	unprivileged = true
	for_each = local.nodes
	vm_id = each.key
	node_name = var.target_node
	started = true
	start_on_boot = true
	tags = var.tags
}
 ```
#### variables.tf
The variables.tf file is where variables are declared a given a type, along with additional metadata fields. You can declare a default value, a description, and even include simple validation steps. 
```terraform
variable target_node {
	type = string
	default = "node"
	description = "proxmox host node"
}
```

[See here for more details from Hashicorp.](https://developer.hashicorp.com/terraform/language/values/variables)
#### terraform.tfvars
The terraform.tfvars file is where all variables declared in variables.tf are assigned. This is generally where usernames/passwords/tokens and other sensitive information should go. **When committing the project to git, ALWAYS include \*.tfvars in your .gitignore file so your secrets are not made publicly available.**

This is basically the variable name created in the variables.tf file, followed by an equal sign, and then the value that must match the type declared in the variables file.

```terraform
target_node = "lab-server"
```

### Additional functionality
- You can declare local variables in a "locals" block between the provider and the resources. This allows you to declare variable key/value maps. Once they've been declared, you can use a for loop to loop through and create multiple devices with unique configuration.
```terraform
locals {
		nodes = {
			101 = {
				name = var.node1_name
				mac = var.node1_mac
			}
		
			102 = {
				name = var.node2_name
				mac = var.node2_mac
			}
		
			103 = {
				name = var.node3_name
				mac = var.node3_mac
			}
		}
	}

	# Then, in resources block, you can assign the variable to for_each, and 
	# then set variables to be the key or value for each pair in the map. 
	# So below will go through each pair in 'nodes' and assign a hostname, mac
	# address, and vmid.

	resource "resource_type" "resource_name" {
		for_each = local.nodes
		node_name = var.target_node
		hostname = each.value.name
	
		network_interface {
			mac_address = each.value.mac
		}
	}

```

## The Impact
- Basic Terraform project structure
- Using for-each loops to create multiple devices with fewer lines of code
