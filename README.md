# Deploy Pyplan onpremise with microk8s

## Provisioning the server with tools and Docker

### Debian
```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt-get install snapd -y
sudo apt install -y net-tools acl
```
    
## Install microk8s
```bash
sudo snap install microk8s --classic --channel=1.21/stable
```
    
## Adding permissions to User
```bash
sudo usermod -a -G microk8s $USER
```
    
## Copy the kubeconfig into ~/.kube/config
```bash
mkdir .kube && cd ~/.kube
sudo chown -f -R $USER ~/.kube
microk8s config > config
```

## Create alias

```bash
sudo snap alias microk8s.kubectl kubectl
```

## Enable addons

```bash
microk8s enable dns ingress rbac dashboard
 ```

## Create folders/user and permisions

```bash
sudo mkdir -p /pyplan/config /pyplan/deploy /pyplan/cert /pyplan/data /pyplan/data/logs /pyplan/data/logs/api /pyplan/data/engine 
sudo adduser --disabled-password --disabled-login --gecos GECOS --uid 101010 pyplan_exec

sudo setfacl -R -m u:101010:rwx /pyplan
sudo setfacl -Rd -m u:101010:rwx /pyplan
sudo setfacl -R -m u:$USER:rwx /pyplan/deploy  #only for copy yaml direct to this folder
sudo setfacl -R -m u:$USER:rwx /pyplan/cert  #only for copy yaml direct to this folder
```

## Copy kubernet yaml file: pyplan.yaml
```bash
scp -i pyplan-tests-us-east-2.pem pyplan.yml user@host:/pyplan/deploy/
```

## Apply deployments
```bash
cd /pyplan/deploy
kubectl apply -f pyplan.yml -n pyplan
```

## Copy and create secret with certs
### Copy the files into /pyplan/cert and create the secret
```bash
scp -i ~/pruebas.pem cert.* user@host:/pyplan/cert/

kubectl create secret tls -n pyplan ingress-tls \
--key /pyplan/cert/cert.key \
--cert /pyplan/cert/cert.pem
```
### Edit pyplan.yml with SSL 
```bash
cd /pyplan/deploy
nano pyplan.yml
kubectl apply -f pyplan.yml -n pyplan
```    

## Letsencrypt
### Apply the manifests
```bash
scp -r lestencrypt user@host:/pyplan/deploy

cd /pyplan/deploy
kubectl apply -f cert-manager.yml issuer.yml
``` 
### Edit pyplan.yml and apply it
```bash
kubectl apply -f pyplan.yml -n pyplan
``` 

## Configuration 

### Set up these resources for the Engine pod in Department Manager
    {"container_params":{"resources":{"limits":{"cpu":"1","memory":"2Gi"},"requests":{"cpu":"0.5","memory":"0.5Gi"}}}}

## Dashboard 
### Apply the manifests, the dashboard login is succesful with the admin Token
```bash
scp -r dashboard user@host:/pyplan/deploy
kubectl apply -f issuer-dashboard.yml
kubectl apply -f ingress-dashboard.yml
cat ~/.kube/config
```

## Backup and restore the database

### Doing a manual backup
```bash
kubectl exec -it [pod_name] -n pyplan -- pg_dump --format=t --dbname=[PG_DB_NAME]--username=[PG_USER]--file=backup.tar
kubectl exec -it pyplan-db-0 -n pyplan -- pg_dump --format=t --dbname=postgres --username=postgres --file=backup.tar
kubectl cp -n pyplan [pod_name]:backup.tar to_restore.tar
kubectl cp -n pyplan pyplan-db-0:backup.tar to_restore.tar
```
### Restoring the database
#### Drop database 
#### Warning: this is a destructive command
```bash
kubectl exec [pod_name] -n pyplan -- dropdb [PG_DB_NAME]
kubectl exec pyplan-db-0 -n pyplan -- dropdb postgres
```
#### Create database
```bash
kubectl exec -it [pod_name] -n pyplan -- createdb -U [PG_USER] [PG_DB_NAME]
kubectl exec -it pyplan-db-0 -n pyplan -- createdb -U postgres postgres
# Copy the backup into the pod [If the pod is deleted]
kubectl cp -n pyplan to_restore.tar pyplan-db-0:/backup.tar
```
#### Restore database
```bash
kubectl exec -it [pod_name] -n pyplan -- pg_restore -v -F t --exit-on-error -d [PG_DB_NAME] -U [PG_USER] backup.tar
kubectl exec -it pyplan-db-0 -n pyplan -- pg_restore -v -F t --exit-on-error -d postgres -U postgres backup.tar
```

## Usefull commands

    - kubectl get all -o wide
    - kubectl describe [pod]
    - kubectl logs [pod]
    - kubectl rollout restart deployment/pyplan-api -n pyplan
    - microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443 --address 0.0.0.0

