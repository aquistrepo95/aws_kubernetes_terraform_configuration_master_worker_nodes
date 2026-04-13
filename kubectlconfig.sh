#!/bin/bash

# set up kubeconfig for the regular user
echo "Setting up kubeconfig for the regular user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install a pod network add-on (Weave Net)
echo "Installing Weave Net pod network add-on..."
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.29/net.yaml
