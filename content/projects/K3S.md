---
title: K3S Setup
type: page
tags:
  - homelab
  - k3s
  - clustering
showTableOfContents: true
---
## The Problem
At work, my team is currently using a kubernetes cluster in Google Cloud to work as a gitlab runner for test automation. The cluster has already been built so I am looking to actually build a cluster. 

Kubernetes clustering can be a major benefit for production applications. Clusters can be set up to scale automatically as demand on an application fluctuates. So demand increases, the cluster can add more pods to meet that demand. Once demand calms down, the nodes can start spinning down unnecessary pods. The nodes also work together to make sure applications are always running on healthy pods. If a pod is identified as unhealthy, the application is moved to a new pod and the malfunctioning pod is restart and/or destroyed.

On my homelab, a kubernetes cluster is practically unnecessary. I am the only one accessing the services so I don't need the scalability or high availability clustering allows for. I'm using this as an opportunity to learn how to configure a cluster, set up shared storage, and deploy applications.
## The Approach
I decided to use k3s instead of kubernetes for this cluster because k3s is touted as a lightweight version of kubernetes for resource-constrained environments.

### A. Installation of k3s
- Quick start guide is crazy easy and fast - [here](https://docs.k3s.io/quick-start)
1. run this command on the machine you plan to use as the control node:
```
curl -sfL https://get.k3s.io | sh -
```
2. Run this command on the worker nodes - get 'mynodetoken' from the control node's /var/lib/rancher/k3s/server/node-token (myserver will be the control's ip address):
```
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```
3. Once complete, run this on the control node:
```
sudo kubectl get nodes
```
- Issue - I could get control server up and running but couldn't get node connected to it, after some research, I learned that the control server was advertising its localhost ip address instead of its actual ip address.
```
# to see what control server is advertising
sudo systemctl cat k3s

# results should include:
  --advertise-address control-server-ip
  
# add the following if the advertise-address is not found in that file
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s server \
  --node-ip control-server-ip \
  --advertise-address control-server-ip
  
# save and restart nodes
```
- When you run the get nodes command again, the worker nodes should appear, but won't have a role assigned to them.
4. Next, assign the worker role to other nodes.
```
kubectl label node <worker1-name> node-role.kubernetes.io/worker=worker
kubectl label node <worker2-name> node-role.kubernetes.io/worker=worker
```
### B. Storage
- The next thing to set up is shared storage for the whole cluster to use and access.
- I am using TrueNAS Scale, so that is where I will create the share for my cluster. This will just include general steps for the setup in TrueNAS using the GUI.
1. Create a resource pool, if you do not already have one.
2. Inside that pool, create a dataset that the cluster will access.
3. Create an NFS share pointing at that new data set.
4. Configure permissions so the cluster user and IP can read and write to the data set. 
	- You'll want to check the UID of the user on the cluster with the following command, then make sure the owner of the share has a match uid (the nfs share on the cluster doesn't really care about the username, just the matching uid).
```
id USERNAME_OF_CLUSTER_USER
```
5. On all of the k3s nodes, install nfs common with:
```
sudo apt install nfs-common
```
6. Temporarily Mount the nfs share on the cluster nodes (make sure mount point path is created on nodes):
```
sudo mount -t nfs IP_OF_NAS:/path/to/share /path/to/node_mount_point
```
6. Permanently mount the nfs share on the nodes (make sure mount point path is created on nodes):
```
sudo nano /etc/fstab
IP_OF_NAS:/path/to/share /path/to/node_mount_point nfs  defaults,_netdev  0  0
```

### C. Persistent Volume Claim (PVC) Setup
- Next, we need to set up a Persistent Volume Claim. This will be used when adding an application to the node. It will allow kubernetes  to create an NFS share and assign it to the application automatically.
1. First, we will need to install helm, which is a package manager for kubernetes.
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
2. check it successfully installed with:
```
helm version
```
2. Install nfs provisioner repository.
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
```
4. Update the helm repo.
```
helm repo update
```
5. Create the helm values.yaml file for nfs-provisioner.
```
mkdir -p ~/kubernetes/apps/nfs-provisioner
nano ~/kubernetes/apps/nfs-provisioner/values.yaml

nfs:
  server: 192.168.x.x
  path: /mnt/pool/k3s

storageClass:
  name: nfs
  defaultClass: true
  reclaimPolicy: Retain
```
6. Install the helm chart and point it at nfs share created earlier.
```
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=IP_OF_NAS \
  --set nfs.path=/path/to/share
```
7. You may need to modify file permissions.
```
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```
8. Verify.
```
kubectl get pods -n nfs-provisioner
```
9. Create a test persistent volume claim (pvc).
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 1Gi
EOF
```
10. Check it's creation, after 10 - 30 seconds, the result should say bound.
```
kubectl get pvc test-pvc
```
11. Check your nfs share mount point on the cluster and see if files are autogenerated there.
12. After the test is successful you can clean up by deleting the test PVC.
```
kubectl delete pvc test-pvc
```
### D. Ingress Controller (Traefik)
- This will be done when I move out of my homelab VM and into my main VLAN, as I already have Traefik set up to access apps by url and setting up SSL certificates with Let'sEncrypt.

### E. Application Deployment - MetalLB
- MetalLB is a load balancer. After being installed onto the control node, it can be configured with a range of IPs. These IP addresses should be unused and outside of your router's dhcp range. Once configured, we can deploy another application. That application will be given an available IP address in the configured range.
1. Add the helm repo for MetalLB.
```
helm repo add metallb https://metallb.github.io/metallb
helm repo update
```
2. Create the values.yaml file on the node.
```
mkdir -p ~/kubernetes/apps/metallb
nano ~/kubernetes/apps/metallb/values.yaml
```
3. Add the following:
```
controller:
  enabled: true
```
4. Install MetalLB.
```
helm install metallb metallb/metallb \
  -f ~/kubernetes/apps/metallb/values.yaml \
  -n metallb-system \
  --create-namespace
```
5. After about a minute, run the following command to verify the pods are running (there will be 4):
```
kubectl get pods -n metallb-system
```
6. Create the MetalLB Manifest, this will be where we configure the IP address range it will use.
```
nano ~/kubernetes/apps/metallb/ippool.yaml
```
7. Add the following, using your own values.
```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.0.150-192.168.0.175
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
```
8. Verify the IP pool was created.
```
kubectl get ipaddresspool -n metallb-system
```
9. Now another application can be deployed with helm and it will be given one of these IP addresses. You will use the given ip to access the app.

## The Impact
### What did I learn?
#### 1. k3s setup
- As I said, the installation of k3s was incredibly easy. Just a couple commands and my three ubuntu nodes were clustered with shared storage.
#### 2. Persistent Volume Claim (PVC)
- Storage Class Set up Analogy
	Imagine you're at a hotel:
	- You don't go find your own room — you just say **"I need a room"**
	- The hotel automatically assigns you one based on what's available
	Storage Class works the same way:
	- Your app says **"I need 10GB of storage"**
	- Kubernetes automatically creates a volume on your NFS share and assigns it to the app
	- You don't have to manually create storage for every app
#### 3. Ingress Controller
- While I didn't set up an ingress control yet, I did learn some valuable information. Using traefik, we can route all http/https traffic for cluster applications through a single IP address assigned by MetalLB. Then, we can set up a DNS server on another MetalLB-assigned IP. With this set up, we can access our services using local domain names instead of IP addresses and port numbers.
#### 4. Application deployment
- Using Helm, application installation can also be incredibly simple. adding the repo then running the repo's install command is enough. After that, you configure the application the same way you would if you installed it manually or any way other than Helm.

