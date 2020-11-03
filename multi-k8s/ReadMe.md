
```
brew install kubectl
brew cask install minikube
https://www.virtualbox.org/wiki/Downloads

# minikube start
# minikube ip
# minikube docker-env
# eval $(minikube docker-env)


minikube stop && minikube delete && minikube start --vm=true --driver=hyperkit

minikube addons enable ingress
eval $(minikube -p minikube docker-env)



kubectl apply -f xxxx.yaml

kubectl apply -f k8s/

kubectl get deployments
kubectl get services
kubectl get pods
kubectl get ingresses
kubectl get ep

kubectl logs <pod id>

kubectl delete deployment client-deployment


kubectl create secret  generic pgpassword \
--from-literal PGPASSWORD=abd12345!

kubectl get secrets

kubectl get storageclass
kubectl describe storageclass
kubectl get pv
kubectl get pvc

kubectl set image deployments/server-deployment server=stephengrider/multi-server:$Version

minikube dashboard
```

## Run the Project
```
cd /Users/yongliu/docker_course/multi-k8s

minikube stop && minikube delete && minikube start --vm=true --driver=hyperkit

# https://kubernetes.github.io/ingress-nginx/deploy/#minikube

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.40.2/deploy/static/provider/cloud/deploy.yaml


# kubectl apply -f ingress-nginx-deploy.yaml

minikube addons enable ingress
eval $(minikube -p minikube docker-env)


kubectl create secret  generic pgpassword \
--from-literal PGPASSWORD=abd12345!

kubectl apply -f k8s_dev/

minikube dashboard

```

## Fix Issue
```
 kubectl get pod -A
kubectl describe pod ingress-nginx-controller-98cb87fb7-pdr6x -n ingress-nginx

 minikube ssh
 docker pull quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.33.0


```

## Useful docker CMD and images
```
docker system prune

docker run -t --rm -v ~:/root -v /:/mnt/fs -p 8000:8000 coderaiser/cloudcmd

```

## Entrie Deployment Flow

![Entrie Flow](./jpgs/k8s_overview.jpg)

![Master](./jpgs/k8s_overview2.jpg)


## Why Service

![Why Service](./jpgs/why_service.jpg)

## Node port
![](./jpgs/node-port.jpg)


## Connecting to Running Containers
![Connecting to Running Containers](./jpgs/node-port-service.jpg)

## The Path to Production
![The Path to Production](./jpgs/path-to-prod.jpg)


## NodePort vs. ClusterIP
![ NodePort vs. ClusterIP](./jpgs/nodePort-vs-ClusterIP.jpg)



## ClusterIP
![ClusterIP](./jpgs/clusterIp.jpg)
 

## Volume
![pvc](./jpgs/why_volume.jpg)
![volume](./jpgs/volume.jpg)

## Volume belongs to Pod
![volume](./jpgs/volume-in-pod.jpg)

## Volume vs. Persistent Volume 
![Volume vs. Persistent Volume](./jpgs/pv.jpg)

## What is Persistent Volume Claim 
![pvc](./jpgs/what_is_pvc.jpg)


## PVC 
![access modes](./jpgs/pvc_access_mode.jpg)
```yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-persistent-volume-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: postgres
  template:
    metadata:
      labels:
        component: postgres
    spec:
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: database-persistent-volume-claim
      containers:
        - name: postgres
          image: postgres
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
              subPath: postgres
          env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: pgpassword
                  key: PGPASSWORD

```

![](./jpgs/how-pvc-work.jpg)

```sh
kubectl get storageclass
kubectl describe storageclass
kubectl get pv
kubectl get pvc

```

![](./jpgs/how-pvc-work-cloud.jpg)
```
kubectl get pv
kubectl get pvc
```
![](./jpgs/get-pv.jpg)

## Secret
![secret](./jpgs/secret.jpg)
![](./jpgs/create-secret.jpg)

```
kubectl create secret  generic pgpassword \
--from-literal PGPASSWORD=abd12345!

kubectl get secrets
```


## Load Balancer
![](./jpgs/lb.jpg)

## Ingress 

![](./jpgs/ingress.jpg)
![](./jpgs/nginx-ingress.jpg)
![](./jpgs/ingress-on-google-cloud.jpg)

https://kubernetes.github.io/ingress-nginx/deploy/
