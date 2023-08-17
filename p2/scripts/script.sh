#!/bin/bash

cd /etc/yum.repos.d/
sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -

# wait for the k3s cluster to setup properly
kubectl get jobs -n kube-system 
kubectl -n kube-system wait --for=condition=complete --timeout=-1s jobs/helm-install-traefik-crd
kubectl -n kube-system wait --for=condition=complete --timeout=-1s jobs/helm-install-traefik
kubectl get jobs -n kube-system

sleep 10

echo "deploying manifests"


/usr/local/bin/kubectl config set-context --current --namespace=kube-system

/usr/local/bin/kubectl apply -f /vagrant/confs/app3.yaml --validate=false
/usr/local/bin/kubectl apply -f /vagrant/confs/manifest.yaml --validate=false
/usr/local/bin/kubectl apply -f /vagrant/confs/owncloud.yaml --validate=false
/usr/local/bin/kubectl apply -f /vagrant/confs/ingress.yaml --validate=false
