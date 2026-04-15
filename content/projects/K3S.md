---
title: K3S Setup
type: page
tags:
  - homelab
  - k3s
  - clustering
  - traefik
  - certs
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
```bash
curl -sfL https://get.k3s.io | sh -
```
2. Run this command on the worker nodes - get 'mynodetoken' from the control node's /var/lib/rancher/k3s/server/node-token (myserver will be the control's ip address):
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```
3. Once complete, run this on the control node:
```bash
sudo kubectl get nodes
```
- Issue - I could get control server up and running but couldn't get node connected to it, after some research, I learned that the control server was advertising its localhost ip address instead of its actual ip address.
```bash
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
```bash
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
```bash
id USERNAME_OF_CLUSTER_USER
```
5. On all of the k3s nodes, install nfs common with:
```bash
sudo apt install nfs-common
```
6. Temporarily Mount the nfs share on the cluster nodes (make sure mount point path is created on nodes):
```bash
sudo mount -t nfs IP_OF_NAS:/path/to/share /path/to/node_mount_point
```
6. Permanently mount the nfs share on the nodes (make sure mount point path is created on nodes):
```bash
sudo nano /etc/fstab
IP_OF_NAS:/path/to/share /path/to/node_mount_point nfs  defaults,_netdev  0  0
```

### C. Persistent Volume Claim (PVC) Setup
- Next, we need to set up a Persistent Volume Claim. This will be used when adding an application to the node. It will allow kubernetes  to create an NFS share and assign it to the application automatically.
1. First, we will need to install helm, which is a package manager for kubernetes.
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
2. check it successfully installed with:
```bash
helm version
```
3. Install nfs provisioner repository.
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
```
4. Update the helm repo.
```bash
helm repo update
```
5. Create the helm values.yaml file for nfs-provisioner.
```bash
mkdir -p ~/kubernetes/apps/nfs-provisioner
nano ~/kubernetes/apps/nfs-provisioner/values.yaml
```

```text
nfs:
  server: 192.168.x.x
  path: /mnt/pool/k3s

storageClass:
  name: nfs
  defaultClass: true
  reclaimPolicy: Retain
```
6. Install the helm chart and point it at nfs share created earlier.
```bash
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=IP_OF_NAS \
  --set nfs.path=/path/to/share
```
7. You may need to modify file permissions.
```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```
8. Verify.
```bash
kubectl get pods -n nfs-provisioner
```
9. Create a test persistent volume claim (pvc).
```bash
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
```bash
kubectl get pvc test-pvc
```
11. Check your nfs share mount point on the cluster and see if files are autogenerated there.
12. After the test is successful you can clean up by deleting the test PVC.
```bash
kubectl delete pvc test-pvc
```
#### helpful troubleshooting
- to get a detailed look at the current state of the test pvc after creation if stuck pending
```
kubectl describe pvc test-pvc
```
### D. Ingress Controller with Let'sEncrypt Certs
- We need a way to access the services on the cluster without have to use ip addresses, since the app could be running on any of the nodes. The plan is to use local dns records with a real domain name. So instead of IP addresses, URLs can be used to access apps. 
- Also, by using Cloudflare with Let'sEncrypt, we can avoid the warnings the browser gives when navigating to an uncertified domain.
#### - Cloudflare Token Creation
1. In cloudflare, go to My Profile -> API Tokens -> Create Token.
2. Create Custom Token.
3. Name the token.
4. Under permissions, select Zone | DNS | Edit.
5. Add another permission, select Zone | DNS | Read
6. Under zone resources, select Include | Specific Zone | your domain.
7. Copy/save token for later.
8. Verify it works with, it should show your domain in the results:
```bash
TOKEN='your-token-here' curl -X GET "https://api.cloudflare.com/client/v4/zones" \ -H "Authorization: Bearer $TOKEN" \ -H "Content-Type: application/json" | python3 -m json.tool
```

#### - Cert Manager install and ClusterIssuer creation
1.  On your cluster control server, install cert-manager helm repository.
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```
2. Verify successful installation.
```bash
kubectl get pods -n cert-manager
```
3. After install, you can store the cloudflare token as a secret on the cluster control server.
```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=YOUR_TOKEN_HERE \
  -n cert-manager
```
4. After install, the message will mention a ClusterIssuer will need created. On your control server, create a file called clusterissuer.yaml with the following content:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: you@yourdomain.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
		selector:
			dnsZones:
				- "your.domain.com"
```
5. Then run the following command:
```bash
kubectl apply -f clusterissuer.yaml
```

#### DNS Setup
- This will assume PiHole is already running on an LXC in Proxmox.
1. ssh into or use proxmox console for the PiHole lxc.
2. open the following file (create if needed):
```bash
sudo nano etc/dnsmasq.d/k3s.conf
```
3. Add the following wildcard entry:
```
address=/.yourdomain.com/ip-of-control-server
```
4. Restart PiHole-FTL.
```bash
sudo systemctl restart pihole-FTL
```
5. Validate on another machine using nslookup:
```bash
nslookup test.your.domain.com
```
**Issue: I kept seeing this error when running nslookup:**
```
server can't find test.your.domain.com: NXDOMAIN
```
- If you see the same, do the following:
1. Make sure your pihole is up-to-date (I was running an old version).
```bash
pihole -up
```
2. Afterwards, you need to enable the system to include configs created inside of dnsmasq.d.
```bash
sudo pihole-FTL --config misc.etc_dnsmasq_d true
```
3. Restart FTL and try nslookup again.
```bash
sudo systemctl restart pihole-FTL
```
### E. Test
1. On the cluster control server, create smoke-test.yaml and add:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: smoke-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: smoke-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami-svc
  namespace: smoke-test
spec:
  selector:
    app: whoami
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami
  namespace: smoke-test
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - whoami.home.goshsamit.com
      secretName: whoami-tls
  rules:
    - host: whoami.home.goshsamit.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami-svc
                port:
                  number: 80
```
2. Deploy the test:
```bash
kubectl apply -f smoke-test.yaml
```
3. Wait for the provisioning step to flip to TRUE (wait a couple minutes)
```bash
kubectl get certificate -n smoke-test -w
```
4. Test with curl:
```bash
curl -I https://whoami.your.domain.com
```
5. Once passed, clean up the test:
```bash
kubectl delete namespace smoke-test
```
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
- Using traefik, we can route all http/https traffic for cluster applications through a single IP address assigned by MetalLB. Then, we can set up a DNS server on another MetalLB-assigned IP. With this set up, we can access our services using local domain names instead of IP addresses and port numbers.
#### Flow diagram of traffic
Browser -> PiHole DNS (*.your.domain.com points to control node) -> Traefik (reverse proxy + TLS termination) -> cert-manager (Let's Encrypt certs via Cloudflare DNS-01) -> Your service pods

