#!/bin/bash

echo "\n#--------------------------MINIKUBE SETUP--------------------------------\n"

#checking if brew is installed
which -s brew
if [[ $? != 0 ]] ; then
	echo "Installing Brew..."
	rm -rf $HOME/.brew && git clone --depth=1 https://github.com/Homebrew/brew $HOME/.brew && export PATH=$HOME/.brew/bin:$PATH && brew update && echo "export PATH=$HOME/.brew/bin:$PATH" >> ~/.zshrc &> /dev/null
fi

#checking if minikube is installed
which -s minikube
if [[ $? != 0 ]] ; then
	echo -ne "\033[1;31m+>\033[0;33m Minikube installation ...\n"
	if brew install minikube &> /dev/null
	then
		echo -ne "\033[1;32m+>\033[0;33m Minikube installed ! \n"
	else
		echo -ne "\033[1;31m+>\033[0;33m Error... During minikube installation. \n"
		return 0
	fi
fi

echo "set minikube_home"
export MINIKUBE_HOME=/Users/$(whoami)/goinfre

echo "Deleting previous cluster if there is one"
minikube delete

echo "Starting Minikube (it might take a while)"
minikube start --vm-driver=virtualbox
eval $(minikube docker-env)


echo "\n#-------------------------- METALLB CONFIG ------------------------------\n"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

#ConfigMap MetalLB
kubectl apply -f ./srcs/yaml/metallb-configmap.yaml
echo "\n#-------------------------------- LUNCH DASHBOARD ----------------------------\n"
minikube dashboard &

echo "\n#------------------------------- REQUEST VOLUMES ----------------------------\n"

#Volume
kubectl apply -f srcs/yaml/mysql-vl.yaml
kubectl apply -f srcs/yaml/influxdb-vl.yaml

echo "\n#------------------------------ MYSQL IMAGE BUILD ----------------------------\n"

#remove existing mysql image
docker rmi mysql-img

#build mysql image
docker build -t mysql-img ./srcs/mysql/

#mysql deployment and service
kubectl apply -f ./srcs/yaml/mysql.yaml

echo "\n#------------------------------ INFLUXDB IMAGE BUILD ----------------------------\n"

#remove existing influxdb image
docker rmi influxdb-img

#build influxdb image
docker build -t influxdb-img srcs/influxdb/.

#influxdb deployment and service
kubectl apply -f srcs/yaml/influxdb.yaml

echo "\n#----------------------------- NGINX  ----------------------------\n"

#remove existing nginx image
docker rmi nginx-img

#build nginx image
docker build -t nginx-img ./srcs/nginx/

#nginx deployment and service
kubectl apply -f ./srcs/yaml/nginx.yaml


echo "\n#------------------------------- FTPS IMAGE BUILD ----------------------------\n"

#remove existing ftps image
docker rmi ftps-img

#build ftps image
docker build -t ftps-img srcs/ftps/.

#ftps deployment and service
kubectl apply -f srcs/yaml/ftps.yaml

echo "\n#------------------------------- PHPMYADMIN ----------------------------\n"

#remove existing phpmyadmin image
docker rmi php-img

#build nginx image
docker build -t php-img ./srcs/phpmyadmin/

#phpmyadmin deployment and service
kubectl apply -f ./srcs/yaml/phpmyadmin.yaml

echo "\n#------------------------------ GRAFANA IMAGE BUILD ----------------------------\n"

#remove existing grafana image
docker rmi grafana-img

#build grafana image
docker build -t grafana-img srcs/grafana/.

#grafana deployment and service
kubectl apply -f srcs/yaml/grafana.yaml

# # echo "\n#--------------------------- WORDPRESS IMAGE BUILD ----------------------------\n"

#remove existing wordpress image
docker rmi wordpress-img

#build wordpress image
docker build -t wordpress-img ./srcs/wordpress/

#wordpress deployment and service
kubectl apply -f ./srcs/yaml/wordpress.yaml



kubectl exec -i `kubectl get pods | grep -o "mysql\S*"` -- mysql -u root < srcs/mysql/srcs/wordpress.sql


echo done.
