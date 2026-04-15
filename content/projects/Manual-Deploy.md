---
title: Manual Application Deployment for k3s Cluster
type: page
tags:
  - homelab
  - k3s
  - clustering
date: 2026-04-15
showTableOfContents: true
---
## The Problem
Now that we have a cluster set up with storage, a persistent volume claim, ingress control, as well as local dns, we need something for all of this to do. I figured a good start would be a dashboarding app where we can get all of our future apps and services in one place and easily accessible. 

I've been using the [Homepage Dashboard](https://gethomepage.dev/) on a docker container for over a year now, so now I plan to move it to the k3s cluster. This setup below will be for homepage, but other applications should be set up similarly. 

Homepage Dashboard is configurable with xmls and can act as a "bookmarks" page for apps and services. It also has the ability to pull metrics and display them for various applications. I plan to just use the bookmarks page functionality so this guide will not include individual app metrics. This requires additional Role-Based Access Control (RBAC) set up that I will not be doing here.

## The Approach
1. On the control node, create the homepage namespace
```bash
kubectl create namespace homepage
```
2. On the control node, create a "homepage" directory and cd into that new directory.
```bash
mkdir homepage && cd homepage
```
3. Create a "manifests" and "config" directories
```
mkdir manifests && mkdir config
```
4. create the following manifest files with the touch command:
```bash
touch manifests/homepage-deployment.yaml
touch manifests/homepage-service.yaml
touch manifests/clusterissuer.yaml
touch manifests/homepage-ingress.yaml
```
5. Create the following config files with the touch command:
```bash
touch config/settings.yaml
touch config/bookmarks.yaml
touch config/services.yaml
touch config/widgets.yaml
```
6. Edit the settings.yaml and copy in the following (the other files can be blank):
```yaml
title: Homepage
```
7. Create the homepage config map:
```bash
kubectl create configmap homepage-config --from-file=settings.yaml --from-file=bookmarks.yaml --from-file=services.yaml --from-file=widgets.yaml -n homepage
```
8. cd into manifests directory and edit homepage-deployment.yaml file:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homepage
  namespace: homepage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: homepage
  template:
    metadata:
      labels:
        app: homepage
    spec:
      containers:
        - name: homepage
          image: ghcr.io/gethomepage/homepage:latest
          ports:
            - containerPort: 3000
          volumeMounts:
            - name: config
              mountPath: /app/config
      volumes:
        - name: config
          configMap:
            name: homepage-config
```
9. Apply the deployment manifest:
```bash
kubectl apply -f homepage-deployment.yaml
```
10. From the manifests directory, edit the homepage-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: homepage
  namespace: homepage
spec:
  selector:
    app: homepage
  ports:
    - port: 3000
      targetPort: 3000
```
11. Apply the service manifest:
```bash
kubectl apply -f homepage-service.yaml
```
12. From the manifests directory, edit the clusterissuer.yaml
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: you@yourdomain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: traefik
```
12. Apply the clusterissuer manifest
```bash
kubectl apply -f manifests/clusterissuer.yaml
```
13. From the manifests directory, edit the homepage-ingress.yaml.
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homepage
  namespace: homepage
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - homepage.yourdomain.com
      secretName: homepage-tls                          
  rules:
    - host: homepage.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: homepage
                port:
                  number: 3000
```
14. Apply the ingress manifest:
```bash
kubectl apply -f homepage-ingress.yaml
```
15. Validate it is working with kubectl
```bash
kubectl get pods -n homepage
kubectl get svc -n homepage
kubectl get ingress -n homepage
```
16. Once running, open browser and navigate to homepage.yourdomain.local and you should hit your new homepage dashboard without a certificate error
17. You can update the config files as you wish based on [homepage docs](https://gethomepage.dev/configs/).
18. Once edited, you'll need to patch the ConfigMap from step 7:
```bash
kubectl create configmap homepage-config --from-file=settings.yaml --from-file=services.yaml --from-file=bookmarks.yaml --from-file=widgets.yaml -n homepage --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/homepage -n homepage
```
## The Impact
- This project taught me the differences between deploying an app to docker vs deploying an app to k3s. With docker being straight forward to set up, deploying an app on a container is as simple as configuring a docker-compose file, which is typically provided by the application or service doc website. The k3s install was a little more involved, due to the initial set up and configuration the cluster required. Once the cluster or containers are set up however, application config is fairly straightforward on k3s as well. Directory creation, manifest creation so the cluster can handle ingress control when the app is running on a pod, and service creation that the application can run as a service on the cluster.