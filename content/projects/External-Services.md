---
title: Adding Local DNS and TLS Certs for External Services
type: page
tags:
  - homelab
  - certs
  - traefik
  - dns
date: 2026-04-17
showTableOfContents: true
---
## The Problem
A couple of my self-hosted services cannot be apart of the kubernetes cluster, storage and DNS. These services are running on a separate VM and LXC so the cluster can access them. If they were on the cluster, we would have some sort of circular reasoning where the cluster needs them, but the cluster is the one serving them. 

Proxmox is also running the cluster node virtual machines, so obviously cannot be apart of the cluster.

My network has a router, a switch, and a couple access points. I would like to access these with a local DNS name and not having to deal with the non-valid certificate error message. 

## The Approach
### Namespace Creation
1. Create the following directory on your cluster node if it does not already exist:
```bash
mkdir apps/external-services
```
2. Create the namespace yaml file on the cluster control node.
```bash
nano apps/external-services/namespace.yaml
```
3. Add the following to the namespace.yaml:
```yaml
apiVersion: v1
kind: Namespace
metadata:
	name: external-services
```
4. Apply the namespace creation.
```bash
kubectl apply -f apps/external-services/namespace.yaml
```

### Shared ServersTransports Creation
- For these external services, most will skip TLS certificate verification if they have a self-signed HTTPS cert. Proxmox needs a separate configuration as it does not support HTTP/2. Trying to use HTTP/2 with proxmox leads to a re-direct loop. 
1. Create the TLS certificate verification yaml:
```bash
nano apps/external-services/skip-verify-transport.yaml
```
2. Add the following:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: skip-verify
  namespace: external-services
spec:
  insecureSkipVerify: true
```
3. Create the proxmox-specific yaml:
```bash
nano apps/external-services/proxmox-transport.yaml
```
4. Add the following:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: ServersTransport
metadata:
  name: proxmox-transport
  namespace: external-services
spec:
  insecureSkipVerify: true
  disableHTTP2: true
```
5. Apply the two configs:
```bash
kubectl apply -f apps/external-services/skip-verify-transport.yaml
kubectl apply -f apps/external-services/proxmox-transport.yaml
```

### Wildcard Cert Creation
- One certificate is going to apply to all of the external services. Because of this, a wildcard cert is needed so it can handle the various name differences with the services. Cert-manager will manage certificate renewal with Cloudflare.
1. Create the certificate yaml:
```bash
nano apps/external-services/wildcard-certificate.yaml
```
2. Add the following:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-home-domain-com
  namespace: external-services
spec:
  secretName: wildcard-home-your-domain-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - "home.domain.com"
    - "*.home.domain.com"
```
3. Apply the config:
```bash
kubectl apply -f apps/external-services/wildcard-certificate.yaml
```
4. Run the following to watch for verification. Ready should switch to TRUE in about a minute:
```bash
kubectl get certificate -n external-services -w
```
- Troubleshooting: cert is stuck in FALSE - I ran into an issue where Traefik loaded before the secret for the verified certification existed, so it ran with an error. 
1. Restart the traefik deployment:
```bash
kubectl rollout restart deployment traefik -n kube-system
```
2. If having further issues, run the following commands to get detailed logs of what is going on.
```bash
kubectl describe certificate wildcard-home-domain-com -n external-services
kubectl describe certificaterequest wildcard-home-domain-com-1 -n external-services
kubectl describe order <order-name> -n external-services
kubectl get challenges -n external-services
```

### Ingress Pattern
- Each external service IP is accessible via HTTP or HTTPS.
	- If HTTP: Ingress
		- This includes my access points and network switch.
	- If HTTPS: IngressRoute
		- Proxmox, pfsense, pihole, and TrueNAS
- This will affect the service yaml files in the next step.

### Service Deployment
1. Create a file for each external service you would like to add:
```
nano /apps/external-services/SERVICE-NAME.yaml
```
2. Edit Files with below templates.
3. Apply the configs:
```bash
kubectl apply -f apps/external-services/SERVICE-NAME.yaml
```
4. Validate the cert is ready:
```bash
kubectl get certificate -n external-services
```
5. Validate all the ingresses exist:
```bash
kubectl get ingress,ingressroute -n external-services
```
6. Validate there are no errors in Traefik
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=50 | grep -i error
```
#### Ingress with HTTP
- Replace NAME-OF-SERVICE, SERVICE-IP-ADDRESS, and SERVICE for the local domain name.
- Make sure the domain below is your domain.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: NAME-OF-SERVICE
  namespace: external-services
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: NAME-OF-SERVICE
  namespace: external-services
subsets:
  - addresses:
      - ip: SERVICE-IP-ADDRESS
    ports:
      - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: NAME-OF-SERVICE
  namespace: external-services
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: "websecure"
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - SERVICE.home.domain.com
      secretName: wildcard-home-domain-com-tls
  rules:
    - host: switch.home.domain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: NAME-OF-SERVICE
                port:
                  number: 80
```

#### Ingress Route with HTTP redirect (PiHole)
- Pi-Hole's UI is accessed via IP-ADRESS/admin, so it requires a slightly different setup.
- Replace PIHOLE-IP and make sure the domain is your domain.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: pihole
  namespace: external-services
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: pihole
  namespace: external-services
subsets:
  - addresses:
      - ip: PIHOLE-IP
    ports:
      - port: 80
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: pihole-redirect
  namespace: external-services
spec:
  redirectRegex:
    regex: "^https://pihole\\.home\\.DOMAIN\\.com/$"
    replacement: "https://pihole.home.DOMAIN.com/admin/"
    permanent: false
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: pihole
  namespace: external-services
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`pihole.home.DOMAIN.com`)
      kind: Rule
      middlewares:
        - name: pihole-redirect
      services:
        - name: pihole
          port: 80
  tls:
    secretName: wildcard-home-DOMAIN-com-tls
```

#### IngressRoute with HTTPS
- Replace NAME-OF-SERVICE, SERVICE-IP, and domain name.
- When this is fully set up and you try to access PFSense (if you are using it), you will be hit with a "Potential DNS Rebind Attack." Log into PFSense via the IP address, navigate to 
```yaml
apiVersion: v1
kind: Service
metadata:
  name: NAME-OF-SERVICE
  namespace: external-services
spec:
  type: ClusterIP
  ports:
    - port: 443
      targetPort: 443
---
apiVersion: v1
kind: Endpoints
metadata:
  name: NAME-OF-SERVICE
  namespace: external-services
subsets:
  - addresses:
      - ip: SERVICE-IP
    ports:
      - port: 443
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: NAME-OF-SERVICE
  namespace: external-services
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`SERVICE.home.DOMAIN.com`)
      kind: Rule
      services:
        - name: pfsense
          port: 443
          scheme: https
          serversTransport: skip-verify
  tls:
    secretName: wildcard-home-DOMAIN-com-tls
```

#### Proxmox IngressRoute with HTTPS
- Replace PROXMOX-IP and DOMAIN
```
apiVersion: v1
kind: Service
metadata:
  name: proxmox
  namespace: external-services
spec:
  type: ClusterIP
  ports:
    - port: 8006
      targetPort: 8006
---
apiVersion: v1
kind: Endpoints
metadata:
  name: proxmox
  namespace: external-services
subsets:
  - addresses:
      - ip: PROXMOX-IP
    ports:
      - port: 8006
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: proxmox
  namespace: external-services
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`proxmox.home.DOMAIN.com`)
      kind: Rule
      services:
        - name: proxmox
          port: 8006
          scheme: https
          serversTransport: proxmox-transport
  tls:
    secretName: wildcard-home-DOMAIN-com-tls
```
## The Impact
- Further creation and configuration of kubernetes apps and service