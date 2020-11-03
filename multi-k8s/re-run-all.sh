
echo  "minikube stop && minikube delete && minikube start --vm=true --driver=hyperkit"
minikube stop && minikube delete && minikube start --vm=true --driver=hyperkit

echo "kubectl apply -f ingress-nginx-deploy.yaml"
kubectl apply -f ingress-nginx-deploy.yaml

echo "minikube addons enable ingress"

minikube addons enable ingress
eval $(minikube -p minikube docker-env)

kubectl create secret  generic pgpassword \
--from-literal PGPASSWORD=abd12345!

kubectl apply -f k8s_dev/

minikube dashboard 

