
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

kubectl exec -it [pod_name] [cmd]
e.g: kubectl exec -it auth-depl-9889dbb7c-hk56c sh

kubectl describe pod [pod_name] 

kubectl logs <pod id>
kubectl logs -f $(kubectl get po | egrep -o 'usermgmt-microservice-[A-Za-z0-9-]+')

kubectl logs -f $(kubectl get pods | grep usermgmt-microservice | awk '{print $1 }')

kubectl delete deployment client-deployment


kubectl create secret  generic pgpassword \
--from-literal PGPASSWORD=abd12345!

kubectl get secrets

kubectl get storageclass
kubectl describe storageclass
kubectl get pv
kubectl get pvc

kubectl scale --replicas=30 deploy ca-demo-deployment 

Version=$(git rev-parse HEAD)
kubectl set image deployments/server-deployment server=stephengrider/multi-server:$Version

// force to pull new images for all
kubectl rollout restart deployment
kubectl rollout restart deployment  [deployment]

// port-forward, similar to NodePort svc, useful for temp test
kubectl port-forward [pod-name] [port:targetPort]
kubectl port-forward nats-depl-b946946dd-2zns2 4222:4222
 

minikube dashboard
```

## Create EKS Node Group in Private Subnets

```
eksctl get nodegroup --cluster=<Cluster-Name>
eksctl get nodegroup --cluster=eksdemo1

eksctl delete nodegroup <NodeGroup-Name> --cluster <Cluster-Name>
eksctl delete nodegroup eksdemo1-ng-public1 --cluster eksdemo1
 
eksctl create nodegroup --cluster=eksdemo1 \
                        --region=us-east-1 \
                        --name=eksdemo1-ng-private1 \
                        --node-type=t3.medium \
                        --nodes-min=2 \
                        --nodes-max=4 \
                        --node-volume-size=20 \
                        --ssh-access \
                        --ssh-public-key=kube-demo \
                        --managed \
                        --asg-access \
                        --external-dns-access \
                        --full-ecr-access \
                        --appmesh-access \
                        --alb-ingress-access \
                        --node-private-networking   
kubectl get nodes -o wide


# Create Cluster without-nodegroup
eksctl create cluster --name=eksdemo1 \
                      --region=us-east-1 \
                      --zones=us-east-1a,us-east-1b \
                      --without-nodegroup 

# Get List of clusters
eksctl get clusters  

```


## Create & Associate IAM OIDC Provider for our EKS Cluster
  
  To enable and use AWS IAM roles for Kubernetes service accounts on our EKS cluster, we must create & associate OIDC identity provider.

```
# Replace with region & cluster name
eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster eksdemo1 \
    --approve
```    

## update kubectl context 
```

cluster_name=photowall-eks-cluster-dev
aws eks update-kubeconfig --name $cluster_name

kubectl config view --minify


https://stackoverflow.com/questions/50791303/kubectl-error-you-must-be-logged-in-to-the-server-unauthorized-when-accessing

cluster_name=photowall-eks-cluster-dev
aws eks update-kubeconfig --name $cluster_name \
--role-arn  arn:aws:iam::717087451485:role/PhotowallCodepipelineBuildPojectRole


```

## Get the IAM role Worker Nodes 
```
# Get Worker node IAM Role ARN
kubectl -n kube-system describe configmap aws-auth

# from output check rolearn
rolearn: arn:aws:iam::180789647333:role/eksctl-eksdemo1-nodegroup-eksdemo-NodeInstanceRole-IJN07ZKXAWNN

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
## Connect to MySQL
```
kubectl run -it --rm --image=mysql:5.7.22 --restart=Never mysql-client -- mysql -h usermgmtdb.c7hldelt9xfp.us-east-1.rds.amazonaws.com -u dbadmin -pdbpassword11


mysql> show schemas;
mysql> create database usermgmt;
mysql> show schemas;
mysql> exit
```


## Generate Load
```
kubectl run --generator=run-pod/v1 apache-bench -i --tty --rm --image=httpd -- ab -n 500000 -c 1000 http://<Service-Name>.default.svc.cluster.local/ 
```

## cross namespace access in the cluster
```
http://<Service-Name>.<namespace>.svc.cluster.local/ 

http://my-release-ingress-nginx-controller.default.svc.cluster.local

```

## Create iamserviceaccount
```
eksctl create iamserviceaccount \
    --name xray-daemon \
    --namespace default \
    --cluster eksdemo1 \
    --attach-policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess \
    --approve \
    --override-existing-serviceaccounts
    

kubectl get sa
 
# Describe Service Account (Verify IAM Role annotated)
kubectl describe sa xray-daemon

# List IAM Roles on eksdemo1 Cluster created with eksctl
eksctl  get iamserviceaccount --cluster eksdemo1

```
## ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: xray-daemon
  name: xray-daemon
  namespace: default
  # Update IAM Role ARN created for X-Ray access
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::180789647333:role/eksctl-eksdemo1-addon-iamserviceaccount-defa-Role1-VR2R60B6MMDV
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: xray-daemon
  namespace: default
spec:
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: xray-daemon
  template:
    metadata:
      labels:
        app: xray-daemon
    spec:
      serviceAccountName: xray-daemon
      volumes:
        - name: config-volume
          configMap:
            name: "xray-config"
      containers:
        - name: xray-daemon
          image: amazon/aws-xray-daemon
          command: ["/usr/bin/xray", "-c", "/aws/xray/config.yaml"]
          resources:
            requests:
              cpu: 256m
              memory: 32Mi
            limits:
              cpu: 512m
              memory: 64Mi
          ports:
            - name: xray-ingest
              containerPort: 2000
              hostPort: 2000
              protocol: UDP
            - name: xray-tcp
              containerPort: 2000
              hostPort: 2000
              protocol: TCP
          volumeMounts:
            - name: config-volume
              mountPath: /aws/xray
              readOnly: true
---
# Configuration for AWS X-Ray daemon
apiVersion: v1
kind: ConfigMap
metadata:
  name: xray-config
  namespace: default
data:
  config.yaml: |-
    TotalBufferSizeMB: 24
    Socket:
      UDPAddress: "0.0.0.0:2000"
      TCPAddress: "0.0.0.0:2000"
    Version: 2
---
# k8s service definition for AWS X-Ray daemon headless service
apiVersion: v1
kind: Service
metadata:
  name: xray-service
  namespace: default
spec:
  selector:
    app: xray-daemon
  clusterIP: None
  ports:
    - name: xray-ingest
      port: 2000
      protocol: UDP
    - name: xray-tcp
      port: 2000
      protocol: TCP
```


## Entrie Deployment Flow

![Entrie Flow](./jpgs/k8s_overview.jpg)

![Master](./jpgs/k8s_overview2.jpg)


## Why Service

![Why Service](./jpgs/why_service.jpg)

## Node port
![](./jpgs/node-port.jpg)

![node port svc](./jpgs/node_port_svc.jpg)
![access node port svc](./jpgs/access_node_prot_svc.jpg)


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
## Secret in yaml 
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-db-password
#type: Opaque means that from kubernetes's point of view the contents of this Secret is unstructured.
#It can contain arbitrary key-value pairs. 
type: Opaque
data:
  # Output of echo -n 'dbpassword11' | base64
  db-password: ZGJwYXNzd29yZDEx
  
  
---

            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-db-password
                  key: db-password
                  
```

# valueFrom - ref pod name in Env as ClientId

```yaml
env:
            - name: NATS_CLIENT_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
```

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: tickets-depl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tickets
  template:
    metadata:
      labels:
        app: tickets
    spec:
      containers:
        - name: tickets
          image: amliyong/tickets
          env:
            - name: NATS_CLIENT_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: NATS_URL
              value: 'http://nats-srv:4222'
            - name: NATS_CLUSTER_ID
              value: ticketing
            - name: MONGO_URI
              value: 'mongodb://tickets-mongo-srv:27017/tickets'
            - name: JWT_KEY
              valueFrom:
                secretKeyRef:
                  name: jwt-secret
                  key: JWT_KEY
```


## Init Containers & livenessProbe & readinessProbe
```yaml

template:
    metadata:
      labels:
        app: usermgmt-restapp
    spec:
      initContainers:
        - name: init-db
          image: busybox:1.31
          command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z mysql 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']
          
---

 livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - nc -z localhost 8095
            initialDelaySeconds: 60
            periodSeconds: 10
            
---

  readinessProbe:
            httpGet:
              path: /usermgmt/health-status
              port: 8095
            initialDelaySeconds: 60
            periodSeconds: 10     
            

---

   resources:
            requests:
              memory: "128Mi" # 128 MebiByte is equal to 135 Megabyte (MB)
              cpu: "500m" # `m` means milliCPU
            limits:
              memory: "500Mi"
              cpu: "1000m"  # 1000m is equal to 1 VCPU core                                          
              


```

## Namesapce

```
# List Namespaces
kubectl get ns 

# Craete Namespace
kubectl create namespace <namespace-name>
kubectl create namespace dev1
kubectl create namespace dev2


kubectl apply -f kube-manifests/ -n dev1
kubectl apply -f kube-manifests/ -n dev2

# List all objects from dev1 & dev2 Namespaces
kubectl get all -n dev1
kubectl get all -n dev2


```
```yaml
piVersion: v1
kind: Namespace
metadata:
  name: dev3
  
```
## LimitRange and ResourceQuota for namespace
```yaml



apiVersion: v1
kind: Namespace
metadata: 
  name: dev3
---  
apiVersion: v1
kind: LimitRange
metadata:
  name: default-cpu-mem-limit-range
  namespace: dev3
spec:
  limits:
    - default:
        cpu: "500m"  # If not specified default limit is 1 vCPU per container     
        memory: "512Mi" # If not specified the Container's memory limit is set to 512Mi, which is the default memory limit for the namespace.
      defaultRequest:
        cpu: "300m" # If not specified default it will take from whatever specified in limits.default.cpu      
        memory: "256Mi" # If not specified default it will take from whatever specified in limits.default.memory
      type: Container 
      


---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ns-resource-quota
  namespace: dev3
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi  
    pods: "5"    
    configmaps: "5" 
    persistentvolumeclaims: "5" 
    replicationcontrollers: "5" 
    secrets: "5" 
    services: "5" 
    
```

## ExternalName Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  type: ExternalName
  externalName: usermgmtdb.c7hldelt9xfp.us-east-1.rds.amazonaws.com
```  

## Amazon EBS CSI Driver

https://github.com/amliuyong/aws-eks-kubernetes-masterclass/tree/master/04-EKS-Storage-with-EBS-ElasticBlockStore

```

# Get Worker node IAM Role ARN
kubectl -n kube-system describe configmap aws-auth

# from output check rolearn
rolearn: arn:aws:iam::180789647333:role/eksctl-eksdemo1-nodegroup-eksdemo-NodeInstanceRole-IJN07ZKXAWNN

# Attach Policy to role
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}

# Deploy EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# Verify ebs-csi pods running
kubectl get pods -n kube-system

```

## Load Balancer
![](./jpgs/lb.jpg)

```yaml

apiVersion: v1
kind: Service
metadata:
  name: clb-usermgmt-restapp
  labels:
    app: usermgmt-restapp
spec:
  type: LoadBalancer  # Regular k8s Service manifest with type as LoadBalancer
  selector:
    app: usermgmt-restapp     
  ports:
  - port: 80
    targetPort: 8095
    
    
---

apiVersion: v1
kind: Service
metadata:
  name: nlb-usermgmt-restapp
  labels:
    app: usermgmt-restapp
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb    # To create Network Load Balancer
spec:
  type: LoadBalancer # Regular k8s Service manifest with type as LoadBalancer
  selector:
    app: usermgmt-restapp     
  ports:
  - port: 80
    targetPort: 8095
    
    
```

## Ingress 

![](./jpgs/ingress.jpg)
![](./jpgs/nginx-ingress.jpg)
![](./jpgs/ingress-on-google-cloud.jpg)


### ingress-nginx/ingress-nginx

https://kubernetes.github.io/ingress-nginx/deploy/
https://github.com/kubernetes/ingress-nginx/tree/master/deploy/static/provider/cloud


```
# https://kubernetes.github.io/ingress-nginx/deploy/#docker-for-mac

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update

# helm install my-release ingress-nginx/ingress-nginx


# sudo vi /etc/hosts, add below line
# 127.0.0.1       posts.com
```
#### ingress ingress-srv example

https://github.com/amliuyong/react-microservices/blob/main/01_A-Mini-Microservices-App/infra/k8s/ingress-srv.yaml

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-srv
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: 'true'
spec:
  rules:
    - host: posts.com
      http:
        paths:
          - path: /posts/create
            backend:
              serviceName: posts-clusterip-srv
              servicePort: 4000
          - path: /posts
            backend:
              serviceName: query-srv
              servicePort: 4002
          - path: /posts/?(.*)/comments
            backend:
              serviceName: comments-srv
              servicePort: 4001
          - path: /?(.*)
            backend:
              serviceName: client-srv
              servicePort: 3000
```

##  AWS Ingress

### install aws-load-balancer-controller

https://github.com/amliuyong/aws-eks-kubernetes-masterclass/tree/master/08-ELB-Application-LoadBalancers

 1.  ALB Install Ingress Controller
 https://github.com/amliuyong/aws-eks-kubernetes-masterclass/tree/master/08-ELB-Application-LoadBalancers/08-01-ALB-Ingress-Install

 2. AWS ALB Ingress Controller - Implement HTTP to HTTPS Redirect 
https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/ingress/annotation/


```sh
#!/usr/bin/env bash

clusterName=photowall-eks-cluster-${STAGE_NAME}

CLUSTER=$clusterName

echo ACCOUNT_ID=${ACCOUNT_ID}
echo CLUSTER=$CLUSTER

kubectl get deployment -n kube-system aws-load-balancer-controller

if [[ $? -eq 0 ]];
then
   echo "aws-load-balancer-controller alreay installed"
   exit 0;
fi 

eksctl utils associate-iam-oidc-provider \
    --region ap-northeast-2 \
    --cluster $CLUSTER \
    --approve

curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy-${STAGE_NAME} \
    --policy-document file://iam-policy.json

LBARN=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy-${STAGE_NAME}

eksctl create iamserviceaccount \
  --cluster=$CLUSTER \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=$LBARN\
  --override-existing-serviceaccounts \
  --approve

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

## Install helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add eks https://aws.github.io/eks-charts


helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=$CLUSTER \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system

kubectl get deployment -n kube-system aws-load-balancer-controller

# kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

```

```yaml

# Annotations Reference:  https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/ingress/annotation/
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-usermgmt-restapp-service
  labels:
    app: usermgmt-restapp
  annotations:
    # Ingress Core Settings  
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/scheme: internet-facing
    # Health Check Settings
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP 
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
    #alb.ingress.kubernetes.io/healthcheck-path: /usermgmt/health-status
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/success-codes: '200'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    ## SSL Settings
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:180789647333:certificate/9f042b5d-86fd-4fad-96d0-c81c5abc71e1
    #alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-1-2017-01 #Optional (Picks default if not used)    
    # SSL Redirect Setting
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'   
spec:
  rules:
    #- host: ssldemo.kubeoncloud.com    # SSL Setting (Optional only if we are not using certificate-arn annotation)
    - http:
        paths:
          - path: /* # SSL Redirect Setting
            backend:
              serviceName: ssl-redirect
              servicePort: use-annotation            
          - path: /app1/*
            backend:
              serviceName: app1-nginx-nodeport-service
              servicePort: 80                        
          - path: /app2/*
            backend:
              serviceName: app2-nginx-nodeport-service
              servicePort: 80            
          - path: /*
            backend:
              serviceName: usermgmt-restapp-nodeport-service
              servicePort: 8095              
# Important Note-1: In path based routing order is very important, if we are going to use  "/*", try to use it at the end of all rules. 

```
   3. External DNS - Used for Updating Route53 RecordSets from Kubernetes
   
   https://github.com/amliuyong/aws-eks-kubernetes-masterclass/tree/master/08-ELB-Application-LoadBalancers/08-06-ALB-Ingress-ExternalDNS/08-06-01-Deploy-ExternalDNS-on-EKS
   

## Rollout New Deployment
```

# Rollout New Deployment by updating yaml manifest 2.0.0
kubectl apply -f kube-manifests/

# Verify Rollout Status
kubectl rollout status deployment/notification-microservice

# Verify ReplicaSets
kubectl get rs

# Verify Rollout History
kubectl rollout history deployment/notification-microservice

# Access Application (Should see V2)
https://services.kubeoncloud.com/usermgmt/notification-health-status

# Roll back to Previous Version
kubectl rollout undo deployment/notification-microservice

# Access Application (Should see V1)
https://services.kubeoncloud.com/usermgmt/notification-health-status

```

## Codepipeline 

### Create STS Assume IAM Role for CodeBuild to interact with AWS EKS
```
# Export your Account ID
export ACCOUNT_ID=xxxxxxxxxxx

# Set Trust Policy
TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"

# Verify inside Trust policy, your account id got replacd
echo $TRUST

# Create IAM Role for CodeBuild to Interact with EKS
aws iam create-role --role-name EksCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'

# Define Inline Policy with eks Describe permission in a file iam-eks-describe-policy
echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/iam-eks-describe-policy

# Associate Inline Policy to our newly created IAM Role
aws iam put-role-policy --role-name EksCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-eks-describe-policy

# Verify the same on Management Console
```
### Update EKS Cluster aws-auth ConfigMap with new role created in previous step
```
# Verify what is present in aws-auth configmap before change
kubectl get configmap aws-auth -o yaml -n kube-system

# Export your Account ID
export ACCOUNT_ID=180789647333

# Set ROLE value
ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/EksCodeBuildKubectlRole\n      username: build\n      groups:\n        - system:masters"

# Get current aws-auth configMap data and attach new role info to it
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml

# Patch the aws-auth configmap with new role
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"

# Verify what is updated in aws-auth configmap after change
kubectl get configmap aws-auth -o yaml -n kube-system

```

### Review the buildspec.yml for CodeBuild
```yaml
version: 0.2
phases:
  install:
    commands:
      - echo "Install Phase - Nothing to do using latest Amazon Linux Docker Image for CodeBuild which has all AWS Tools - https://github.com/aws/aws-codebuild-docker-images/blob/master/al2/x86_64/standard/3.0/Dockerfile"
  pre_build:
      commands:
        # Docker Image Tag with Date Time & Code Buiild Resolved Source Version
        - TAG="$(date +%Y-%m-%d.%H.%M.%S).$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 8)"
        # Update Image tag in our Kubernetes Deployment Manifest        
        - echo "Update Image tag in kube-manifest..."
        - sed -i 's@CONTAINER_IMAGE@'"$REPOSITORY_URI:$TAG"'@' kube-manifests/01-DEVOPS-Nginx-Deployment.yml
        # Verify AWS CLI Version        
        - echo "Verify AWS CLI Version..."
        - aws --version
        # Login to ECR Registry for docker to push the image to ECR Repository
        - echo "Login in to Amazon ECR..."
        - $(aws ecr get-login --no-include-email)
        # Update Kube config Home Directory
        - export KUBECONFIG=$HOME/.kube/config
  build:
    commands:
      # Build Docker Image
      - echo "Build started on `date`"
      - echo "Building the Docker image..."
      - docker build --tag $REPOSITORY_URI:$TAG .
  post_build:
    commands:
      # Push Docker Image to ECR Repository
      - echo "Build completed on `date`"
      - echo "Pushing the Docker image to ECR Repository"
      - docker push $REPOSITORY_URI:$TAG
      - echo "Docker Image Push to ECR Completed -  $REPOSITORY_URI:$TAG"    
      # Extracting AWS Credential Information using STS Assume Role for kubectl
      - echo "Setting Environment Variables related to AWS CLI for Kube Config Setup"          
      - CREDENTIALS=$(aws sts assume-role --role-arn $EKS_KUBECTL_ROLE_ARN --role-session-name codebuild-kubectl --duration-seconds 900)
      - export AWS_ACCESS_KEY_ID="$(echo ${CREDENTIALS} | jq -r '.Credentials.AccessKeyId')"
      - export AWS_SECRET_ACCESS_KEY="$(echo ${CREDENTIALS} | jq -r '.Credentials.SecretAccessKey')"
      - export AWS_SESSION_TOKEN="$(echo ${CREDENTIALS} | jq -r '.Credentials.SessionToken')"
      - export AWS_EXPIRATION=$(echo ${CREDENTIALS} | jq -r '.Credentials.Expiration')
      # Setup kubectl with our EKS Cluster              
      - echo "Update Kube Config"      
      - aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
      # Apply changes to our Application using kubectl
      - echo "Apply changes to kube manifests"            
      - kubectl apply -f kube-manifests/
      - echo "Completed applying changes to Kubernetes Objects"           
      # Create Artifacts which we can use if we want to continue our pipeline for other stages
      - printf '[{"name":"01-DEVOPS-Nginx-Deployment.yml","imageUri":"%s"}]' $REPOSITORY_URI:$TAG > build.json
      # Additional Commands to view your credentials      
      #- echo "Credentials Value is..  ${CREDENTIALS}"      
      #- echo "AWS_ACCESS_KEY_ID...  ${AWS_ACCESS_KEY_ID}"            
      #- echo "AWS_SECRET_ACCESS_KEY...  ${AWS_SECRET_ACCESS_KEY}"            
      #- echo "AWS_SESSION_TOKEN...  ${AWS_SESSION_TOKEN}"            
      #- echo "AWS_EXPIRATION...  $AWS_EXPIRATION"             
      #- echo "EKS_CLUSTER_NAME...  $EKS_CLUSTER_NAME"             
artifacts:
  files: 
    - build.json   
    - kube-manifests/*
```
### Update CodeBuild Role to have access to STS Assume Role
1. Create STS Assume Role Policy

```
Service: STS
Actions: Under Write - Select AssumeRole
Resources: Specific
Specify ARN for Role: arn:aws:iam::xxxxxxxxxxx:role/EksCodeBuildKubectlRole

```
2. Associate Policy to CodeBuild Role


## How to login cluster which is created by code pipeline


If you run the code pipeline to create EKS clusters, the clusters were create by below CodeBuild role: 

arn:aws:iam::xxxxxxxxxxx:role/PhotowallCodepipelineBuildPojectRole

If you want to login the cluster and run kubectl commands, you need to do following configuration: 

For example, your aws cli user is "eks-user", you can run `aws sts get-caller-identity` to verify your user name



1. Add the assume role permission to the eks-user
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::xxxxxxxxxxx:role/PhotowallCodepipelineBuildPojectRole"
        }
    ]
}
```
2. Edit below trust relationship on the role `PhotowallCodepipelineBuildPojectRole`, so that it will allow the eks-user to assume the role.

  // Trust Relationship of the role
```json
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::xxxxxxxxxxx:user/eks-user"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```
3. update-kubeconfig in your local matchine
```
aws eks --region region-code update-kubeconfig --name <cluster_name> --role-arn arn:aws:iam::xxxxxxxxxxx:user/PhotowallCodepipelineBuildPojectRole

<cluster_name> can be: photowall-eks-cluster-dev | photowall-eks-cluster-stage, run `eksctl get cluster` to verify
```

4. now, you can run kubectl commands as normal. run `kubectl get pods` to verify


# ES on K8s, vagrant, skaffold
https://github.com/amliuyong/esNote/blob/master/ESonK8s_Notes.md


- skaffold
https://github.com/amliuyong/react-microservices/blob/main/01_A-Mini-Microservices-App/skaffold.yaml

```
skaffold dev

```

# ElasticSearch - Fluentd - Kibana - on K8s cluster

https://github.com/amliuyong/Logging-in-K8s-EFK



# K8s Dashboard

- install dashboard
https://github.com/kubernetes/dashboard

- create sample user to get token

https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md


```

// https://github.com/kubernetes/dashboard/blob/master/aio/deploy/recommended.yaml
// https://github.com/amliuyong/Docker_K8s/blob/main/multi-k8s/k8s-dashboard.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.1.0/aio/deploy/recommended.yaml
kubectl proxy
 
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.
 
// create a user and get token

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF


cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

```
## access dashboard
```
kubectl proxy

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.
```

## token for user `admin-user`
```
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```


# Frontend

- Nginx example 

```config
server {
  listen 80;

  location /api/ {
    proxy_pass http://tasks-service.default:8000/;
  }
  
  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
    try_files $uri $uri/ /index.html =404;
  }
  
  include /etc/nginx/extra-conf.d/*.conf;
}
```

- Nginx example 2
```conf
upstream client {
  server client:3000;
}

upstream api {
  server api:5000;
}

server {
  listen 80;

  location / {
    proxy_pass http://client;
  }

  location /sockjs-node {
    proxy_pass http://client;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
  }

  location /api {
    rewrite /api/(.*) /$1 break;
    proxy_pass http://api;
  }
}

```
```

```

- Dockerfile for react App
```dockerfile
FROM node:14-alpine as builder

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

RUN npm run build

FROM nginx:1.19-alpine

COPY --from=builder /app/build /usr/share/nginx/html

COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD [ "nginx", "-g", "daemon off;" ]
```

# EFS 

### Craete EFS and install CSI driver

https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html

### k8s config
https://github.com/amliuyong/react-microservices/blob/main/05_kub-aws-eks/kubernetes/users.yaml

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity: 
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-59d14521
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  name: users-service
spec:
  selector:
    app: users
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: users
  template:
    metadata:
      labels:
        app: users
    spec:
      containers:
        - name: users-api
          image: academind/kub-dep-users:latest
          env:
            - name: MONGODB_CONNECTION_URI
              value: 'mongodb+srv://maximilian:wk4nFupsbntPbB3l@cluster0.ntrwp.mongodb.net/users?retryWrites=true&w=majority'
            - name: AUTH_API_ADDRESS
              value: 'auth-service.default:3000'
          volumeMounts:
            - name: efs-vol
              mountPath: /app/users
      volumes:
        - name: efs-vol
          persistentVolumeClaim: 
            claimName: efs-pvc


```
