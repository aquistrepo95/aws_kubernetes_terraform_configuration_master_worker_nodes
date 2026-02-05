#!/bin/bash
#t2.medium
set -e

# set hostname of node
echo "Setting hostname to master-node..."
hostnamectl set-hostname $1

# disable swap
echo "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# load necessary kernel modules
echo "Loading necessary kernel modules..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# Set sysctl params required by Kubernetes
echo "Setting sysctl parameters for Kubernetes..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv6.conf.all.forwarding        = 1
net.net filter.nf_conntrack_max    = 131072
EOF

#net.bridge.bridge-nf-call-ip6tables = 1

sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward net.ipv6.conf.all.forwarding net.netfilter.nf_conntrack_max
modprobe br_netfilter
sysctl -p /etc/sysctl.conf

# install container runtime docker
echo "Installing Docker..."
#apt clean -y
apt update -y
apt install -y ca-certificates curl apt-transport-https
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker


#install docker CRI
echo "Configuring Docker as the container runtime..."
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb
dpkg -i cri-dockerd_0.3.20.3-0.ubuntu-jammy_amd64.deb

# install kubeadm, kubelet and kubectl
echo "Installing kubeadm, kubelet, and kubectl..."
apt update -y
apt install -y gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt update -y
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# initialize the kubernetes master node
echo "Initializing Kubernetes master node..."
echo "Kubeadm version..."
kubeadm version

# Pre-pull necessary images
echo "Pre-pulling necessary Kubernetes images..."
kubeadm config images pull --cri-socket unix:///var/run/cri-dockerd.sock

# Initialize the Kubernetes cluster
echo "Initializing the Kubernetes cluster with kubeadm..."
kubeadm init --cri-socket unix:///var/run/cri-dockerd.sock

# set up kubeconfig for the regular user
echo "Setting up kubeconfig for the regular user..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# install a pod network add-on (Weave Net)
echo "Installing Weave Net pod network add-on..."
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.29/net.yaml

#echo "Creating file with join command for worker nodes..."
#echo `kubeadm token create --print-join-command` > ./join_command.sh