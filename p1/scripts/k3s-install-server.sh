# sudo apt update
# sudo apt install ufw
# sudo apt install -y curl
# sudo ufw allow 6443/tcp
# curl -sfL https://get.k3s.io | K3S_TOKEN="test123" K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server" sh -s - --flannel-iface eth1

cd /etc/yum.repos.d/
sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo yum update
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo yum install -y curl
sudo firewall-cmd --add-port=6443/tcp --permanent
sudo firewall-cmd --reload
sudo yum install policycoreutils-python-utils
curl -O https://vault.centos.org/centos/8/AppStream/aarch64/os/Packages/container-selinux-2.167.0-1.module_el8.5.0+1006+8d0e68a2.noarch.rpm
sudo rpm -i container-selinux-2.167.0-1.module_el8.5.0+1006+8d0e68a2.noarch.rpm
curl -sfL https://get.k3s.io | K3S_TOKEN="test123" K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="server" sh -s - --flannel-iface eth1
