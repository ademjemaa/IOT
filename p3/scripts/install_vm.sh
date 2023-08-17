#!/bin/bash


# ========== USEFULL TOOLS ============

# takes 2 args : the first as a cmd to run / and the second is the name of the program being tested 
test_cmd_exists () {
	$1 > /dev/null;
	RET=$?
	if [[ $RET == 0 ]]; then
		echo "$2 has been installed successfully"
	else
		echo "$2 failed to be installed. please fix the issue and re-run the script"
		exit 1
	fi
}

# ====== begin installing docker using repo ==========

sudo apt-get update
sudo apt-get install -y \
	ca-certificates \
	curl \
	gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  bullseye stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

test_cmd_exists "docker -v" "Docker"

# ====== end installing docker using repo ==========

# ====== begin installing kubectl using repo ==========
sudo apt-get install -y apt-transport-https
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubectl

test_cmd_exists "kubectl" "Kubernetes kubectl command"


# ====== end installing kubectl ==========

# ====== begin installing k3d using sh script =======
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
test_cmd_exists "kubectl" "Kubernetes kubectl command"
# ====== begin installing k3d using sh script =======

# ====== begin creating the cluster =======

sudo k3d cluster create inception-of-things -p "8080:80@loadbalancer" --wait

# wait for the k3s cluster to setup properly
kubectl get jobs -n kube-system 
kubectl -n kube-system wait --for=condition=complete --timeout=-1s jobs/helm-install-traefik-crd
kubectl -n kube-system wait --for=condition=complete --timeout=-1s jobs/helm-install-traefik
kubectl get jobs -n kube-system

sleep 10

# printing cluster info
sudo kubectl cluster-info
# creating namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

#installing argocd server
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


sudo kubectl wait --for=condition=Ready --timeout=-1s pods --all -n argocd

sudo kubectl patch cm argocd-cmd-params-cm --type merge -n argocd -p '{"data":{"server.insecure":"true"}}'
sudo kubectl rollout restart deployment argocd-server -n argocd
sudo kubectl wait --for=condition=Ready --timeout=-1s pods --all -n argocd

sudo kubectl apply -f ../confs/ingress-argocd.yaml
sudo kubectl apply -f ../confs/ingress-app.yaml
sudo kubectl apply -f ../confs/app-argo-cd.yaml
# sudo kubectl apply -f ../confs/ingress-app.yaml //when argo cd is setup on the port 443 we will put the app on the port 80
# using traefik and remove the Loadbalancer service with port 8888
# the admin password will patched to "iot1234"
sudo kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2y$10$EVmFyCrNLzj82kdeEvM7NO6e/yPi8r0jdj2kuTmK0yOQkgPTedtmq",                                          
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

sudo kubectl rollout restart deployment argocd-server -n argocd

sudo kubectl wait --for=condition=Ready pods --all -n argocd

sudo curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && sudo apt update && sudo apt -y install ngrok
echo "ngrok installed successfully"
ngrok http http://localhost:8080 --log=stdout > /dev/null & 
echo "ngrok running in background"
sudo apt install -y jq
echo "jq installed successfully"
./webhooks.sh
